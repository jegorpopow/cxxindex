# cxxindex
Type-based search tool for C++ declarations

## Build

The tool consist from three componenents
* llvm-based index builder (directory `tool/`). Build instructions can be found in `tool/BUILDING.md`
* llvm-base `auto` resolver (directory `auto-resolver/`). Build instructions can be found in `auto-resolver/BUILDING.md`
* searching tool (directory `backend`)

Searching tool can be launched via
```bash
cd backend
stack build
stack run
```

## Usage 
```bash 
./tool <path-to-source-code-to-index> >> .cxxindex # builds the index file
stack run .cxxindex # searches in index file
```

Query language description: 

Query consisits of function arguments types specification and return type specification. Argument types should be presented as a comma-seprated list in parentheses.
Return type shoudle be highlighted with  `->`. 

Optionally, `forall` section with list of template parameters may prior the main part of a query. 

```
(int, std::vector<int>) -> bool
forall <T : Type> (T, std::size_t) -> std::vector<T>
```




