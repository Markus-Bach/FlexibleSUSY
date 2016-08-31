
BeginPackage["TestSuite`"];

TestEquality::usage="tests equality of two expressions";
TestCloseRel::usage="tests relative numerical difference."
TestLowerThan::usage="tests whether a < b."
TestGreaterThan::usage="tests whether a > b."
TestNonEquality::usage="tests inequality of two expressions";
TestCPPCode::usage="tests a C/C++ code snippet for an expected
result";
PrintTestSummary::usage="prints test summary";
GetNumberOfFailedTests::usage="returns number of failed tests";

Begin["`Private`"];

numberOfFailedTests := 0;
numberOfPassedTests := 0;

GetNumberOfFailedTests[] := numberOfFailedTests;

TestEquality[val_, expr_, msg_:""] := 
    If[val =!= expr,
       numberOfFailedTests++;
       Print["Error: expressions are not equal: ",
             InputForm[val], " =!= ", InputForm[expr]];
       Return[False];,
       numberOfPassedTests++;
       Return[True];
      ];

TestNonEquality[val_, expr_, msg_:""] :=
    If[val === expr,
       numberOfFailedTests++;
       Print["Error: expressions are equal: ",
             InputForm[val], " === ", InputForm[expr]];
       Return[False];,
       numberOfPassedTests++;
       Return[True];
      ];

TestCPPCode[{preface_String, expr_String}, value_String, type_String, expected_String] :=
    Module[{code, output, sourceCode},
           code = expr <> "\n" <>
                  type <> " result__ = " <> value <> ";\n" <>
                  "std::cout << result__ << std::endl;";
           {output, sourceCode} = RunCPPProgram[{preface, code}];
           If[!TestEquality[output, expected],
              Print["The following source code led to this result (",
                    output, "):\n", sourceCode];
             ];
          ];

PrintTestSummary[] :=
    Block[{},
          Print["Test summary"];
          Print["============"];
          If[numberOfFailedTests == 0,
             Print["All tests passed (", numberOfPassedTests, ")."];
             ,
             Print["*** ", numberOfFailedTests, " tests failed!"];
            ];
         ];

RunCPPProgram[{preface_String, expr_String}, fileName_String:"tmp.cpp"] :=
    Module[{code, output = "", errorCode},
           code = "#include <iostream>\n" <>
                  preface <> "\n" <>
                  "int main() {\n" <>
                  expr <>
                  "\nreturn 0;\n}\n";
           Export[fileName, code, "String"];
           errorCode = Run["g++ -o a.out " <> fileName];
           If[errorCode != 0,
              Print["Error: could not compile the following: ", code];
              Return[{"", code}];
             ];
           Run[FileNameJoin[{".","a.out"}], " > a.out.log"];
           If[errorCode != 0, Return[{"", code}]];
           If[MemberQ[FileNames[], "a.out.log"],
              output = Import["a.out.log"];,
              Print["Error: output file \"a.out.log\" not found"];
              Return[{"", code}];
             ];
           DeleteFile[{"a.out", "a.out.log", fileName}];
           Return[{output, code}];
          ];

TestCloseRel[a_?NumericQ, b_?NumericQ, rel_?NumericQ] :=
    If[Abs[a] < rel,
       TestEquality[Abs[a - b] < rel, True],
       TestEquality[Abs[(a - b)/a] < rel, True]
      ];

TestCloseRel[a_List, b_List, rel_?NumericQ] :=
    MapThread[TestCloseRel[#1,#2,rel]&, {Flatten[a], Flatten[b]}];

TestCloseRel[a___] := (
    Print["TestCloseRel: FAIL: ", {a}];
    TestEquality[0,1]);

TestLowerThan[a_?NumericQ, b_?NumericQ] :=
    TestEquality[a < b, True];

TestLowerThan[a___] := (
    Print["TestLowerThan: FAIL: ", {a}];
    TestEquality[0,1]);

TestGreaterThan[a_?NumericQ, b_?NumericQ] :=
    TestEquality[a > b, True];

TestGreaterThan[a___] := (
    Print["TestGreaterThan: FAIL: ", {a}];
    TestEquality[0,1]);

End[];

EndPackage[];
