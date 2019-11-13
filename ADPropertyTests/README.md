# ADPropertyTests

Generates random code to test Swift's Automatic Differentiation.

## Usage

```
swift run ADPropertyTests <path to swiftc>
```

It will generate random code and run swiftc against it until it finds an
interesting failure. Then, it will reduce the code that triggers the failure,
print out the reduced code, and exit.

While it is running, it prints out:

 * The swiftc commands that it is running.
 * A cumulative count of "judgements" (whether it is a success or a known
   failure).
 * Occasional samples of generated code.
