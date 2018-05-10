# Reggie
A Swift domain-specific language (DSL) for crafting Regular Expressions - WORK IN PROGRESS

This is *not* ready for showtime and reuse quite yet.

## To-do
---

- [ ] Add a LICENSE
- [ ] Make it Swift Package Manager compatible
- [ ] Add *unit tests*
- [ ] Add methods to run regular expressions in the DSL itself
- [ ] Maybe don't make `RegularExpressionRepresentable` use lambdas for no reason
- [ ] Documentation
- [ ] Remove the main.swift file which was for homework
- [ ] Remove ambiguity, especially where `RegularExpressionRepresentable...` and `RegularExpressionSequence` are both options for an overloaded helper function, like `oneOf` vs `oneOfSequence`, where using `oneOf` on a `RegularExpressionSequence` would create a faulty choice group (e.g. `(A|B|C)` would be expected, but it'd be `(ABC)`).
- [ ] Consider making choice groups their own class.
- [ ] Consider making `CharacterField` and `ChoiceGroup` (to be created) either implementers of Set algebra through protocols, or make them set-like to be able to add and remove items. Maybe make it just set-like to enforce immutability.
