# Software Security: Input Validation
## Usage
You will need Swift 4.1 installed, which is available with the latest version of Xcode on macOS, or on Ubuntu with a Linux build of Swift ([here](https://swift.org/download/#releases)). If you need to run this on Windows, I am happy to provide a `Dockerfile` upon request. Make sure `swift` is in your `PATH` (i.e. you can run `swift` with no path before it and it works). Double check your version with `swift --version`. All you need to do to run the program is run `./reggie` when inside of the top level of the project. Run `./reggie` by itself to get the help document.

## How it works
The project follows the required format for a Swift Package. Its `Sources` folder contains two build targets: `Reggie`, a Domain Specific Language (DSL) for generating regular expressions (written by me, for this project), and `ReggieApp`, this specific program and its associated validators, built using Reggie. The `Package.swift` file describes `Reggie` as a library that is used by `ReggieApp`, an executable.

This program uses the Swift Package Manager as well as the Swift build system. It does not depend on the Xcode build system. The `./reggie` file is a Bash script that simply runs `swift run`. This command compiles the `ReggieApp` target if necessary (and its dependency, the `Reggie` library), then immediately runs the compiled product. This product resides in the hidden `.build` folder.

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

### Name Validation


## Philosophy
I have opted to not follow the validation cases provided on the assignment document, although I was able in earlier iterations of this project to pass all of those cases. In the case of phone numbers, my rationale is very simple: not a single one of the phone numbers in the Word Document labeled as "acceptable" phone numbers were actually valid, under NANP or E.164. My rationale for how I chose to validate human names, however, is a bit more subjective:

The FCC requires this label on many devices:

> (1) This device may not cause harmful interference, and 
> 
> (2) this device must accept any interference received, including interference that may cause undesired operation.

to disallow names based on arbitrary validation is a very limiting way of handling real human data, and some would argue unethical. It is certainly true that it is impossible to cover all cases, yet engineers love to think of the real world as a simplified and idealized system, to the point where they hold many [misconceptions about human names](https://www.kalzumeus.com/2010/06/17/falsehoods-programmers-believe-about-names/). These myths end up harming real people when the systems they've developed [refuse to acknowledge their existence](https://www.theguardian.com/money/2018/apr/27/etihad-passport-ticket-name-hyphen-airline). Rejecting individuals by their names is one of the simplest and most up-front forms of exclusion — engineers have an imperative to remove biases in their systems that exclude people or discourage their participation

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

## Evaluating my approach (pros and cons)
### Name validation

### Phone number validation

## Scraping country codes
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

## Patterns
```swift
print(makeStandardizedPhoneValidator()!.patternString)

"""
(?:(?:\+1)?[2-9][0-8][0-9][2-9](?:[1][02-9]|[02-9][1]|[02-9][02-9])[0-9]{4}|(?:[+](?:7)[0-9]{4,14}|[+](?:82|41|20|33|31|48|64|45|60|54|63|57|98|47|90|92|89|56|53|43|40|86|30|95|51|52|39|81|44|55|83|32|91|36|61|65|27|93|34|62|28|46|66|84|49|94|58)[0-9]{4,13}|[+](?:212|216|507|227|850|965|997|800|377|999|693|594|696|685|809|964|976|378|857|678|963|887|245|254|504|876|243|210|223|239|230|855|871|222|292|968|996|389|371|253|692|680|684|978|875|990|224|244|255|350|352|219|358|426|688|801|879|966|961|266|291|299|881|859|804|886|217|236|261|806|993|422|599|355|880|889|807|351|508|679|265|686|215|268|697|388|967|974|598|687|269|503|851|670|234|420|681|248|505|597|506|691|296|596|695|264|858|251|852|425|873|971|698|221|998|381|674|970|423|856|242|238|878|220|500|237|379|374|675|259|376|241|372|298|424|429|356|595|383|385|884|218|509|808|683|252|803|969|689|295|235|382|225|962|359|240|877|232|690|994|995|250|233|231|802|853|427|249|428|592|267|256|421|991|972|211|263|502|979|213|671|888|226|290|870|883|373|257|885|591|258|992|677|501|214|676|375|872|882|380|854|293|294|260|247|672|357|590|297|229|977|354|387|673|699|386|874|682|694|960|370|973|246|262|384|805|593|228|975|353)[0-9]{4,12}))
"""
```

NANP: `(?:\+1)?[2-9][0-8][0-9][2-9](?:[1][02-9]|[02-9][1]|[02-9][02-9])[0-9]{4}`

E.164: `(?:[+](?:7)[0-9]{4,14}|[+](?:82|41|...|58)[0-9]{4,13}|[+](?:212|216|...|353)[0-9]{4,12})`