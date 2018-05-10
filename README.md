# Software Security: Input Validation
## Usage
You will need Swift 4.1 installed, which is available with the latest version of Xcode on macOS, or on Ubuntu with a Linux build of Swift ([here](https://swift.org/download/#releases)). If you need to run this on Windows, I am happy to provide a `Dockerfile` upon request. Make sure `swift` is in your `PATH` (i.e. you can run `swift` with no path before it and it works). Double check your version with `swift --version`. All you need to do to run the program is run `./reggie` when inside of the top level of the project. Run `./reggie` by itself to get the help document. Always run `./reggie` while in the same directory as it: the top level of the project.

## How it works
The project follows the required format for a Swift Package. Its `Sources` folder contains two build targets: `Reggie`, a Domain Specific Language (DSL) for generating regular expressions (written by me, for this project), and `ReggieApp`, this specific program and its associated validators, built using Reggie. The `Package.swift` file describes `Reggie` as a library that is used by `ReggieApp`, an executable.

This program uses the Swift Package Manager as well as the Swift build system. It does not depend on the Xcode build system. The `./reggie` file is a Bash script that runs `swift build`, captures the arbitrary build location in `bin` that Swift decides to use, calls the executable there while passing in parameters provided to the `./reggie` script. This command compiles the `ReggieApp` target if necessary (and its dependency, the `Reggie` library) before running.

The program interacts with `reggie.json` in the project root. The program will generate this file if it does not exist when you successfully call a command that requires it. I originally intended to use SQLite, but ran into difficulty in trying to use popular Swift SQLite libraries, so I opted for a JSON flat file, understanding that the database used was not a critical part of the project.

### Reggie
This is the part of the project that I am mainly proud of, and it is the portion to which I devoted the majority of my focus. It is a Swift Domain Specific Language (DSL) for generating complex but safe regular expressions through a composable, human-readable language.

The Reggie library is completely homemade by me after significant reading of the PCRE specification and documentation online. I decided to create this once my handcrafted regexes became too long and complex for my eyes to follow. This is why I've implemented this project in Swift: using a non-strongly-typed language like Python would've made Reggie impossible.

Reggie relies on Swift protocols to generalize the behavior of composable types representing different areas of Regular Expression functionality such as character fields, groups, and string literal sequences. Reggie's architecture allows these components to be built up into larger sequences much like functional combinators in the functional programming domain. I was inspired by the architecture of Parsec, a parser combinator library in Haskell. However, this library is not purely functional and Swift technically cannot have true Monads like those in Haskell due to the lack of [higher-kinded types](https://gist.github.com/CMCDragonkai/a5638f50c87d49f815b8).

The most important component with which a user will interact with `Reggie` is the `ReggiePattern`. After you've used the DSL to build your pattern, you construct a `ReggiePattern`, which will try to convert the components of your DSL expression to a string, and then pass that string to `NSRegularExpression`, which will attempt to compile it, if it's valid. `ReggiePattern` exposes a few functions that enable you to *use* the regex. There are many missing functions, as I've only implemented those necessary for this assignment.

```swift
func example(pattern: ReggiePattern) {
	// the regex pattern as a string
	pattern.patternString
	
	// returns an array of substrings corresponding to matches
	pattern.matches(in: "test")
	
	// is the input string fully covered, once, by the pattern?
	pattern.fullyMatches("test")
	
	// standard regex find-and-replace mode
	pattern.replacingMatches(in: "test", with: "$0$1")
	
	// replace matches with an empty string
	pattern.strippingMatches(in: "test")
}
```

To construct a `ReggiePattern`, you need to pass in a `RegularExpressionRepresentable`. This is not an object, but a protocol. In other languages, you may know this as an `interface`. Protocols in Swift allow for powerfully polymorphic behavior, which enables us to compose heterogeneous types representing different constructs in regex. Anything that is `RegularExpressionRepresentable` can generate a valid regex string of itself that can appear in the top-level of a regex pattern or within a group.

The following items are `RegularExpressionRepresentable`: `Swift.Character`, `CharacterField`, `Group`, `PureRegularExpressionRepresentation`, `RegularExpressionCountable`, `Array where Array.Element == RegularExpressionRepresentable` (to represent sequences), and `Swift.UnicodeScalar`. We can mix and match these types with each other to build complex regexes.

Many of these verbosely named classes can be constructed with helper functions, located in `Sources/Reggie/Helpers.swift`, to make complex composition short and sweet. This project was partially an exploration of these ergonomics.

```swift
let a_b_or_c = CharacterField(withCharacters: [Character("a"), Character("b"), Character("c")], isNegated: true)

// is equivalent to:
let a_b_or_c = chars("abc").negated()
```

But many helpers also generate new functionality, like `oneOf` and `oneOfSequence`, which take `RegularExpressionSequence` objects (glorified arrays) like `(?:ABC)` and transform them into choice groups `(?:A|B|C)` by interspersing `PureRegularExpressionRepresentation` objects `pure("|")`. This latter class is just a convenient tool to inject regex literals into the DSL that will never be escaped.

### ReggieApp
The ReggieApp is a proof of concept for Reggie as well as the implementation of the validators needed for this assignment. Here I implement my own Command Line Interface composition tool following a Router pattern, such that it resembles many web application frameworks. I "register" my routes at the beginning of runtime by assigning a handler lambda to the name of the command (such as `ADD`, `DEL`, and `LIST`), and provide a `Range<Int>` to constrain the valid number of arguments a command can have after it. The lambda receives a `[String]`, an array of strings. This uses the Swift Standard Library `CommandLine` class to get tokenized arguments. That's why the program requires quotes around names or phone numbers with spaces in them.

`main.swift` calls `ReggieApplication`, which gets its validators from `Validators`, manipulates the `reggie.json` file using logic in `ReggieFile` (and Swift's `Codable` interface), registers handlers from `Handlers`, using the CLI router in `CLI`.

```swift
let cli = CLI()
cli.register(
	routeName: "ADD", 
	parameterCount: 2..<3
) { [unowned self] args in
	Handlers.addRoute(app: self, arguments: args)
}
```

## Philosophy
I have opted to not follow the validation cases provided on the assignment document, although I was able in earlier iterations of this project to pass all of those cases. In the case of phone numbers, my rationale is very simple: not a single one of the phone numbers in the Word Document labeled as "acceptable" phone numbers were actually valid, under NANP or E.164. My rationale for how I chose to validate human names, however, is a bit more ideological:

The FCC requires this label on many devices:

> (1) This device may not cause harmful interference, and 
> 
> (2) this device must accept any interference received, including interference that may cause undesired operation.

We have to understand the *intent* behind validating/filtering user input. Presumably, this validation system is meant to be strict, so as to protect fragile systems that that data may run into later in our application pipeline. This may include database queries with SQL injection vulnerabilities, places in our templating engine that allow Cross Site Scripting (XSS), and so on. Such a mechanism is not a sufficient replacement for, or even a temporary alternative to hardening those systems. I believe that a validation step meant to prevent these sorts of problems is misguided, as it ambitiously overextends the actual purpose of data validation: "given user-input data, is it well-structured based on some prototype of that type of data?" — this axiom applies to structured content like phone numbers, street addresses, serial numbers, dates, and so on. Validating phone numbers as structured data against the North American Numbering Plan (NANP) and E.164 standards in this project is actually a useful task. Names, however, are *not* structured data, and there exists no prototypical name; so in this project we are only meant to use validation as a way to protect fragile systems.

To disallow names based on arbitrary validation is a very limiting way of handling real human data, and some would argue unethical. It is certainly true that it is impossible to cover all cases, yet engineers love to think of the real world as a simplified and idealized system, to the point where they hold many [misconceptions about human names](https://www.kalzumeus.com/2010/06/17/falsehoods-programmers-believe-about-names/). These myths end up harming real people when the systems they've developed [refuse to acknowledge their existence](https://www.theguardian.com/money/2018/apr/27/etihad-passport-ticket-name-hyphen-airline). Rejecting individuals by their names is one of the simplest and most up-front forms of exclusion — and engineers have an imperative to remove biases in their systems that exclude people or discourage their participation.

## Assumptions
- There may not be duplicate names or phones in the database. (yes, this is a violation of my above philosophy, but it was added in pursuit of haste rather than correctness). This was mainly to simplify the job of deleting entries — if I had more time, or had spent less time on my DSL, I'd have the CLI ask the user to disambiguate when asking to delete something that appears multiple times, but I'd probably still prevent entries that have the same name *AND* number, just allow repeat names *OR* numbers.
- Humans can have an extremely broad spectrum of legitimate names, and it is not our job to *validate* them per se, or in the sense of determining if they are "real," but we can at least reject names that may harm poorly implemented systems.
- When phone numbers are provided, individuals are going to format them in numerous, illogical, meaningless ways, with arbitrary spacing, parentheses, dashes, and other separators. In the end, it is not our job to judge or validate user's attempts to generate frustrating number formatting: we should apply liberal validation rules to input phone numbers to make sure there is nothing spurious like letters, and then move on to stripping irrelevant characters before actually validating the **numbers themselves** for compliance to NANP or E.164.
- Most phone number fields and validation tools only accept phone numbers themselves, and not extensions. This makes sense: a phone number maps to a single phone *system*, not necessarily a handset. There is no meaningful way to validate extensions, just like there is no meaningful way to validate a phone number that has pause symbols (~) and automated phone system input ("press 1 for..."). This is because phone extensions are entered after one is connected to the target phone system, and the tones are interpreted by that system so that it may route you to a specific handset or subsystem. Therefore, it is sensible that extensions are completely out of scope.
- Phone numbers without a country code or with (+1) are only to be tested as NANP numbers, whereas any other number must follow E.164 stringently (except for requirements about spacing, as we strip spacing and other delimiters before validating numbers for correctness).
- When validating NANP numbers, I assume that numbers still follow the format as found at the time of writing this program, regarding specific rules about what digits can be where in a NANP number (see Wikipedia for North American Numbering Plan).
- When validating E.164 numbers, I ensure that no number, including its country code, exceed 15 digits as per the standard, but beyond that, I made no effort to validate numbers based on their country-specific phone number formats and distribution rules. This would've required far too much research and implementation work, so beyond checking international format compliance, there is no rigorous validity checks.
- For E.164, I assume the shortest national number (excluding country code) is four digits, based on evidence that Saint Helena has the shortest numbers at four digits, and not wanting to allow users to enter special numbers like 911. I based this off the idea that this validation tool was for a business, i.e. eCommerce, and would want valid civilian phones. If the use case were as a phonebook, I would allow practically any number, much like the iPhone does, to facilitate special telephone numbers like 911, or special text numbers that usually consist of five digits.
- Once again considering the above use case, and understanding that in this database, phone numbers are meant as global and absolute identifiers, I forbid or at least ignore the use of international 

## Validation implementation
### Name validation
In my original implementation of name validation, I attempted an ambitious whitelist approach that relied on Unicode Property tags (`\p{_}`) in RegEx (called `UnicodeProperty` in `Reggie`). It accepted all international scripts, including CJK scripts (Chinese, Japanese, and Korean), Hebrew, Arabic, Vietnamese, Extended Latin, and most others. I accomplished this by using the `letter` property: `\p{L}` or `UnicodeProperty.letter.matching()` in `Reggie`. Names could be hyphenated multiple times, but not at the beginnings or ends of words, and there could be a comma after the first token, followed by one or two other tokens following roughly the same rules, delimited by any international whitespace, `UnicodeProperty.separator`. Not only did this work with most imaginable Latin alphabet names, but it worked internationally. However, it did reject people with numbers in their names.
As robust and comprehensive as this implementation was, it was very complex (the pattern generation code in the Reggie DSL taking dozens of lines of code), and a whitelist was the wrong approach for human names, which are always more complex than one may imagine.

As sad as it may be, I deleted that version, the version that was so complex that it necessitated making an entire RegEx DSL, and replaced it with just this:

```swift
let expression = line(
	chars("!@#$%^&*()+=[]{}<>\\|/?:;\r\n\t\\x00").negated().oneOrMore()
)
```

which resolves to the following pattern:

```swift
^[^!@#$%\^&*()+=\[\]{}<>\\|/?:;\r\n\t\\x00]+$
```

It may seem utterly simplistic and not worth weeks of work and research of the PCRE specification, but I believe my large and complex implementation was a learning process to come to this conclusion: that although it is still not perfect, in that it may reject some legitimate names, it is the least restrictive safe approach for using input validation to protect fragile systems from categorical injection attacks.

I do not think that this is a solved problem, or a perfect implementation. I think the whole concept of name validation (as described in "Philosophy") merits reevaluation. I do, however, firmly believe that this minimal, least-invasive blacklist approach is most appropriate for this specific use-case.

#### The old, Unicode Property whitelist approach
This is not what I submitted, but was the end product of a significant amount of work, and could be considered an alternative approach to this problem.
```swift
let fancyApostrophe = char("’")

let unicodeLetter = UnicodeProperty.letter.matching()

let validNameComponent = sequence(
	unicodeLetter,
	char("'").strictlyNonRepeating(),
	fancyApostrophe.strictlyNonRepeating(),
	char(".").strictlyNonRepeating()
)

let validNameWord = oneOfSequence(validNameComponent).oneOrMore()
let hypenatedNameWord = sequence(char("-"), validNameWord)
let unicodeWhitespace = UnicodeProperty.separator.matching()

let exp = line(
	// first name
	validNameWord,
	hypenatedNameWord.maybe(),
	
	// if we don't recursively apply optionality like this
	// [first]([second][third?])?
	// then the second name could be interpreted under third name rules
	// (i.e. if we did it like this: [first][second?][third?])
	sequence(
		// second name
		sequence(
			char(",").maybe(),
			unicodeWhitespace,
			validNameWord,
			hypenatedNameWord.maybe()
		),
		
		// third name (entirely optional)
		sequence(
			unicodeWhitespace,
			validNameWord,
			hypenatedNameWord.maybe()
		).maybe()
	).maybe()
)

let pattern = try? ReggiePattern(exp)
print(pattern?.patternString ?? "Failed")
```

This results in the following pattern:
```regex
^(?:\p{L}|['](?!['])|[\x{2019}](?![\x{2019}])|[.](?![.]))+(?:[\-](?:\p{L}|['](?!['])|[\x{2019}](?![\x{2019}])|[.](?![.]))+)?(?:[,]?\p{Z}(?:\p{L}|['](?!['])|[\x{2019}](?![\x{2019}])|[.](?![.]))+(?:[\-](?:\p{L}|['](?!['])|[\x{2019}](?![\x{2019}])|[.](?![.]))+)?(?:\p{Z}(?:\p{L}|['](?!['])|[\x{2019}](?![\x{2019}])|[.](?![.]))+(?:[\-](?:\p{L}|['](?!['])|[\x{2019}](?![\x{2019}])|[.](?![.]))+)?)?)?$
```

at the outset of this project, I had begun hand typing just such a pattern. When I got to a length much shorter than above, I realized it was illegible and impossible to work with, the impetus for making `Reggie`. I did not dispose this method due to its complexity, but rather because a whitelist approach was inappropriate. I welcome you to try the above pattern. Note: `\x{2019}` represents the "fancy" apostrophe as found in the assignment validation data, probably due to Microsoft Word auto-substituting it for a regular apostrophe. This original method meant to strictly comply with the given test data.

### Telephone validation
Telephone number validation is far less political than human name validation, and this explanation will be a little tidier. I decided that a single regular expression would not sufficiently validate a phone number, and decided to divide the overall problem of testing phone numbers into two major subproblems: first, loosely validating that something resembles a phone number, and then stripping any irrelevant styling and validating the **numbers themselves** for correctness according to the North American Numbering Plan (NANP) or the international E.164 standard.

#### Step one: styled phone number validation
The styling of a phone number has no bearing to an automated system on the actual number. All a phone number needs is digits, and sometimes a plus to discriminate a country code from the rest of the numbers. If the country code is +1, it's a NANP number, meaning it pertains to the US, Canada, or some Caribbean countries. These all follow the same ten digit schemes. As noted in Assumptions, I ignore the possibility of international dialing prefixes (commonly "00" in E.164 countries), long distances prefixes, extensions, etc., because a phone number identifies absolutely **one phone system**, not a subsystem, and does not consider relative dialing codes imposed upon certain subscribers. I allow for a wide and illogical array of spuriously-placed punctuation on phone numbers, in **deliberate conflict** with the provided validation cases, because I have come to the conclusion that people will punctuate their phone numbers however they please, and if you reject it, you will hurt conversion rates, and frustrate people with your bad User Experience. All the styled phone validator does is look for things that are far outside the realm of a properly formatted number without extensions, i.e. alphabet characters.

```swift
func makeStyledPhoneValidator() -> ReggiePattern? {
	return try? ReggiePattern(
		oneOf(
			chars("+","0"..."9",hyphen,enDash,emDash,".","(",")"), unicodeWhitespace
		).oneOrMore()
	)
}
```

this results in the following Regular Expression pattern:

```regex
(?:[+0-9\-\x{2013}\x{2014}.()]|\p{Z})+
```

The variables `hyphen`, `enDash`, `emDash` are defined earlier as `Swift.Character` literals only to disambiguate the characters, which appear identical in monospace fonts. This allow users to provide en-dashes and em-dashes (Option-Minus and Option-Shift-Minus on Mac) in addition to hyphens, in the case that certain input methods "auto-correct" hyphenation to these less common forms. I also allow for any Unicode separator marks, which is defined earlier in `unicodeWhitespace` elsewhere as:

```swift
let unicodeWhitespace = UnicodeProperty.separator.matching()
```

which evaluates test data from the assignment as follows:

```
POSITIVE TESTS
✅ 12345
✅ (703)111-2121
✅ 123-1234
✅ +1(703)111-2121
✅ +32 (21) 212-2324
✅ 1(703)123-1234
✅ 011 701 111 1234
✅ 12345.12345
✅ 011 1 703 111 1234
  
NEGATIVE TESTS
✅ 123
🛑 1/703/123/1234
🛑 Nr 102-123-1234
🛑 <script>alert(“XSS”)</script>
✅ 7031111234
✅ +1234 (201) 123-1234
✅ (001) 123-1234
✅ +01 (703) 123-1234
🛑 (703) 123-1234 ext 204

MY TEST CASES
✅ +1 214 745 4567
✅ +1 (214) 745-4567
✅ +1 214-745-4567
✅ +1 9 03 91 83912
✅ +212 123456789012
✅ +21 1234567890123
✅ +7 12345678901234
✅ +212 1234567890123
✅ +21 12345678901234
✅ +7 123456789012345
```

Bad phone numbers passing this step is not a sign that my validation has failed: this is just the first step. In "MY TEST CASES," note that I have formatted NANP numbers very oddly in some cases: `+1 9 03 91 83912` is an American number spaced more like, say, a British number. It is deliberate that it passes: it shouldn't matter how oddly users format phone numbers if the numbers themselves are valid. Foreign users may even format their local numbers incorrectly according to local standards. This step only extension-less phone numbers.

#### Step 2: De-styling numbers
We use a simple regex to strip irrelevant material from phone numbers now:
```swift
// Validators.swift
func makePhoneDestyler() -> ReggiePattern? {
	return try? ReggiePattern(
		chars("0"..."9","+").negated().oneOrMore()
	)
}

// ReggieApplication.swift (abridged)
guard let phoneDestyler = makePhoneDestyler() else { 
	return nil 
}

let destyled = phoneDestyler.strippingMatches(in: input)
```

The resultant pattern matches *what we want to remove*:
```
[^0-9+]+
```

### Step 3: validating stripped phone numbers
As mentioned earlier, we evaluate numbers on the NANP and E.164 schemas. NANP numbers may be provided with or without a `+1` country code prefix, but all other E.164 numbers must have a 1-3 digit country code.

#### Validating country codes
We could be more liberal (and incorrect) and assume a wide array of country codes, but then several problems would arise:

- users could input nonexistent country codes
- E.164 numbers could not be validated against the requirement that the total length of the number including the country code *NOT* exceed 15 digits,
- we would not be able to discriminate the country code from the rest of the number so as to properly evaluate standards compliance

This necessitated enumerating *all* country codes. I used the Wikipedia article [List of country calling codes](https://en.wikipedia.org/wiki/List_of_country_calling_codes) and the following scraper code (Requests + BeautifulSoup) in Python 3.6:

```py
import requests
from bs4 import BeautifulSoup
import re

page = requests.get('https://en.wikipedia.org/wiki/List_of_country_calling_codes')
soup = BeautifulSoup(page.text, 'html.parser')

text = str(soup.find('table', class_='wikitable'))
matches = re.findall(r'\+\d+', text)
matches = set(matches)

matches = filter(lambda n: len(n)==4, matches)

code_strings = map(lambda c: f'"{c[1:]}"', matches)
print(','.join(code_strings))
```

which was able to provide me a full list of all country codes without the "+" prefix. I stored these separately into `[String]` variables (string arrays) `oneDigitCountryCodes`, `twoDigitCountryCodes`, and `threeDigitCountryCodes` in `Validators.swift`. There is notably only one single-digit country code excluding +1 (which we exclude to evaluate separately with NANP rules), belonging to Russia and Kazakhstan jointly: +7. `Reggie` is capable of transforming these arrays into choice groups without any boilerplate `for` loops, etc. - we keep these different lengths separate so that we can enforce the E.164 maximum digits policy differently for each length.

#### NANP case
Although we end up with one pattern for E.164 and NANP, it is effectively a choice group between two different patterns. For NANP, we use the following evaluation code, following the strict numbering requirements described in [this article](https://en.wikipedia.org/wiki/North_American_Numbering_Plan). Read the source code (`Validators.swift`) for a full explanation of digit requirements enforced by NANP.

```swift
// Validators.swift:makeStandardizedPhoneValidator(),
// abridged

let digit = chars("0"..."9")
let notZeroOrOne = chars("2"..."9")
let notOne = chars("0","2"..."9")
let one = char("1")
let notNine = chars("0"..."8")

let nanpCountryCode = sequence(str("+1"))
let areaCode = sequence(notZeroOrOne, notNine, digit)
let exchange = sequence(
	notZeroOrOne,
	// the second two digits of the exchange code may contain zero or one
	// instances of the digit one.
	oneOf(
		sequence(one,notOne),sequence(notOne,one),sequence(notOne,notOne)
	)
)
let subscriber = digit.repeating(withCount: 4)

let nanp = sequence(
	nanpCountryCode.maybe(), areaCode, exchange, subscriber
)
```

### E.164 case
as mentioned above in the country code section, we've separated country codes by length so that we can write a regex that always enforces the 15-digit max even for different code lengths while still enumerating all real codes explicitly rather than allowing any 1-3 digit country code arbitrarily.

We use the following function to take the arrays of country codes (`String` arrays) and bundle them up into choice groups that `Reggie` can interact with. Given an array `["1", "2", "3"]`, the following function will generate the equivalent of the regex `(?:[+](?:1|2|3))`. Note that `str`, `sequence`, `oneOfSequence`, and `char` are `Reggie` helper functions defined in `Helpers.swift`, not any native Swift methods or constructors. `map` is a Swift function that functionally maps the `str` function onto the array of Strings, turning each of them into a `Reggie` compatible sequence of regex characters by splitting the string into Unicode scalars and casting each of those into either character literals, escaped character literals, or UTF-16 escapes with `\x{_}`. 

```swift
func makePrefixes(codes: [String]) -> RegularExpressionRepresentable {
	return sequence(
		char("+"), 
		oneOfSequence(
			sequence(
				codes.map { str($0) })
			)
	)
}
```

We apply the function as such:

```swift
let oneDigitPrefix   = makePrefixes(codes: oneDigitCountryCodes)
let twoDigitPrefix   = makePrefixes(codes: twoDigitCountryCodes)
let threeDigitPrefix = makePrefixes(codes: threeDigitCountryCodes)
```

Now we have three separate choice group for one, two, and three digit country codes. Although getting this far was laborious and required web scraping and a bit of functional programming, the final wrap up of E.164 validation is a single `Reggie` DSL statement:

```swift
let e164 = oneOf(
	// one digit code variant: 1 + 14 = 15 max
	sequence(oneDigitPrefix, digit.repeating(between: 4...14)),
	// two digit variant: 2 + 13 = 15 max
	sequence(twoDigitPrefix, digit.repeating(between: 4...13)),
	// three digit variant: 3 + 12 = 15 max
	sequence(threeDigitPrefix, digit.repeating(between: 4...12))
)
```

each of these ensures different code lengths correspond with numbers whose cumulative length with the code adds up to no more than 15. 4 was chosen as an arbitrary minimum due to evidence that Saint Helena has the shortest E.164 local components, four digits long. I wanted to disallow special numbers (911) assuming the business case for this validator was to get regular civilian numbers from clients/customers into a business/commerce system, my rationale for such disallowance.

I finally combine the NANP and E.164 cases into a choice group. This is the true power of `Reggie`, being able to build up very complex expression systems in separate variables and steps.

```swift
let expression = oneOf(nanp, e164)
```

Now let's get the pattern by inserting this into `main.swift`:

```swift
print(makeStandardizedPhoneValidator()!.patternString)
```

and here is the pattern:

```regex
(?:(?:\+1)?[2-9][0-8][0-9][2-9](?:[1][02-9]|[02-9][1]|[02-9][02-9])[0-9]{4}|(?:[+](?:7)[0-9]{4,14}|[+](?:82|41|20|33|31|48|64|45|60|54|63|57|98|47|90|92|89|56|53|43|40|86|30|95|51|52|39|81|44|55|83|32|91|36|61|65|27|93|34|62|28|46|66|84|49|94|58)[0-9]{4,13}|[+](?:212|216|507|227|850|965|997|800|377|999|693|594|696|685|809|964|976|378|857|678|963|887|245|254|504|876|243|210|223|239|230|855|871|222|292|968|996|389|371|253|692|680|684|978|875|990|224|244|255|350|352|219|358|426|688|801|879|966|961|266|291|299|881|859|804|886|217|236|261|806|993|422|599|355|880|889|807|351|508|679|265|686|215|268|697|388|967|974|598|687|269|503|851|670|234|420|681|248|505|597|506|691|296|596|695|264|858|251|852|425|873|971|698|221|998|381|674|970|423|856|242|238|878|220|500|237|379|374|675|259|376|241|372|298|424|429|356|595|383|385|884|218|509|808|683|252|803|969|689|295|235|382|225|962|359|240|877|232|690|994|995|250|233|231|802|853|427|249|428|592|267|256|421|991|972|211|263|502|979|213|671|888|226|290|870|883|373|257|885|591|258|992|677|501|214|676|375|872|882|380|854|293|294|260|247|672|357|590|297|229|977|354|387|673|699|386|874|682|694|960|370|973|246|262|384|805|593|228|975|353)[0-9]{4,12}))
```

Without Reggie being able to automatically generate this choice group, building a regex this complex and illegible would be an entirely non-ergonomic programming exercise. Reggie has empowered me to build a complex and correct regular expression with no compromises. Let's break down this regex.

```
(?:\+1)?[2-9][0-8][0-9][2-9](?:[1][02-9]|[02-9][1]|[02-9][02-9])[0-9]{4}
```

The above is the NANP component, following the rules of NANP digit distribution (read `Validators.swift` for full detail of the restrictions). Note that the prefix can be excluded, this allows us to treat NANP as the "default," as many North American businesses do.

```
(?:
[+](?:7)[0-9]{4,14}|
[+](?:82|OMITTED|58)[0-9]{4,13}|
[+](?:212|OMITTED|353)[0-9]{4,12})
```

The above is the E.164, omitting a large number of country codes for legibility and adding line breaks which did not exist in the original. Note that I do not validate local numbers based on country-specific number distribution guidelines: to do so would be an expensive and laborious task in terms of both research and implementation, best left to experts like Google, who have done just that. Essentially, there are three cases for three lengths of country code, again, excluding +1, which is evaluated in NANP.

When we apply our stripped phone number validator above to the stripped phone numbers (i.e. the third step of the process: styled validation, de-styling, standard validation), we get the following results. We use this testing code:

```swift
for phone in phoneNumberStringArray {	
	// first, determine if the number is in an acceptable format given
	// stylization. We are very liberal here, only preventing alphabetic
	// characters and other irrelevant content.
	let isStyledValid = styledPhoneValidator.fullyMatches(phone)
	if !isStyledValid {
		print("🛑 \(phone) - failed style validation")
		continue
	}
	
	let destyled = phoneDestyler.strippingMatches(in: phone)
	
	let isValid = standardPhoneValidator.fullyMatches(destyled)
	if isValid {
		print("✅ \(phone)")
	} else {
		print("🛑 \(phone) - failed standard validation")
	}
}
```

Note that we are also applying the styled validator, and if that fails, we mark it as a failure and exit early: invalidly styled phone numbers never reach the standard validation phase.

```
POSITIVE TESTS  
🛑 12345 - failed standard validation
🛑 (703)111-2121 - failed standard validation
🛑 123-1234 - failed standard validation
🛑 +1(703)111-2121 - failed standard validation
✅ +32 (21) 212-2324
🛑 1(703)123-1234 - failed standard validation
🛑 011 701 111 1234 - failed standard validation
🛑 12345.12345 - failed standard validation
🛑 011 1 703 111 1234 - failed standard validation

NEGATIVE TESTS  
🛑 123 - failed standard validation
🛑 1/703/123/1234 - failed style validation
🛑 Nr 102-123-1234 - failed style validation
🛑 <script>alert(“XSS”)</script> - failed style validation
🛑 7031111234 - failed standard validation
🛑 +1234 (201) 123-1234 - failed standard validation
🛑 (001) 123-1234 - failed standard validation
🛑 +01 (703) 123-1234 - failed standard validation
🛑 (703) 123-1234 ext 204 - failed style validation

MY TEST CASES
✅ +1 214 745 4567
✅ +1 (214) 745-4567
✅ +1 214-745-4567
✅ +1 9 03 91 83912
✅ +212 123456789012
✅ +21 1234567890123
✅ +7 12345678901234
🛑 +212 1234567890123 - failed standard validation
🛑 +21 12345678901234 - failed standard validation
🛑 +7 123456789012345 - failed standard validation
```

Shocking - note that almost none of the phone numbers that the assignment provided as acceptable passed! Surely this means this implementation is narrow and inflexible. But note that they all failed standards validation: upon manual checking, I determined that all but one of these numbers were completely invalid under NANP *and* E.164, either due to:

- using nonexistent country codes
- not following NANP digit constraints for area code, exchange code, or subscriber code
- not following E.164 requirements for length
- not providing a country code when outside of NANP

The non-NANP country code requirement is a requirement I have imposed for disambiguation (at the cost of user experience), and a requirement of E.164 formatting, which exists in that standard for the very same reason.

My test cases mostly succeed, as they begin with actual valid NANP numbers (four of them), followed by three valid E.164 numbers. The last three have valid country codes, but exceed the 15-digit total length requirement. Note when I say "valid" E.164 number, I am referring to the combination of: (1) a real country code, and (2) any group of digits of correct size such that the country code length plus that group's length does not exceed 15. Note once more that the oddly formatted NANP number `+1 9 03 91 83912` is accepted; this appeared earlier in our style check where I rationalized accepting it, here I will rationalize again by explaining: the standard check is receiving stripped numbers consisting only of "+" and digits, and considering those digits, it is a valid NANP number. In the case of the style check, 

## Pros and cons
### Of this project
- the result of over fifty hours of intense research into PCRE regex specifications, Unicode standards, UTF-16 encoding for regex, the Swift type system, combinatorial architectures, international phone number specifications.
- bears the fruit of a powerful, composable, simple to use regular expression engine for building powerful, robust expressions that are too complex to hand-generate
### Name validation
- Probably excepts every human name, unlike other attempts
- Blocks most common SQL injection and XSS payloads, and even HTML character literals `&xxx;`.
- Accepts every written script.
- Not a whitelist approach: this could be a pro or con based on your philosophy
- Much simpler than the Unicode-aware whitelist approach
- Permissive without being unsecure
### Phone number validation
- Completely correct for validation of NANP numbers
- Partially correct for enforcing E.164 on other numbers: proper country code validation and length validation, but no country-specific number validation based on country-specific rules.
- Very long and perhaps slow to compile and execute due to the evaluation of >100 country code literals in the regex
- A complicated multi-step process to validate numbers
- Simplifies validation by separating the style checking, destyling, and standards validation phases
- Prohibits extensions and other components beyond basic, absolute phone numbers, which is more correct, but may worsen the user experience. Probably requires a separate field for extensions if in use in the real world.