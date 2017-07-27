(* Converts the 2-loop SUSY-QCD corrections O(alpha_s^2) to the DR-bar
   top Yukawa coupling in the MSSM from GiNaC form to Mathematica
   form.

   The GiNaC expression in "dmbas2.expr" has been extracted from
   SOFTSUSY 3.7.4 by adding the following C++ code snippet into the
   file
   src/two_loop_thresholds/two_loop_archives/bquark_corrections.cpp
   right after the cache has been filled:

   if (cache.size() == 1) {
      ofstream out("dmbas2.expr");
      out << cache[0] << endl;
   }

   Note: The expression does not include the 2-loop factor 1/(4 Pi)^4 .
 *)

str = Import["dmbas2.expr", "String"];
ex  = ToExpression[StringReplace[str, "--" -> "+"], TraditionalForm];
ex >> "dmbas2.m"
