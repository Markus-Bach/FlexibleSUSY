BeginPackage["FlexibleSUSY`",
             {"SARAH`",
              "AnomalousDimension`",
              "BetaFunction`",
              "Parameters`",
              "TextFormatting`",
              "CConversion`",
              "TreeMasses`",
              "EWSB`",
              "Traces`",
              "SelfEnergies`",
              "Vertices`",
              "Phases`",
              "LatticeUtils`",
              "LoopMasses`",
              "WriteOut`",
              "Constraint`",
              "ThresholdCorrections`",
              "ConvergenceTester`",
              "Utils`",
              "SemiAnalytic`",
              "ThreeLoopSM`",
              "ThreeLoopMSSM`",
              "Observables`",
              "GMuonMinus2`",
              "EffectiveCouplings`",
              "FlexibleEFTHiggsMatching`",
              "FSMathLink`",
              "FlexibleTower`"}];

$flexiblesusyMetaDir     = DirectoryName[FindFile[$Input]];
$flexiblesusyConfigDir   = FileNameJoin[{ParentDirectory[$flexiblesusyMetaDir], "config"}];
$flexiblesusyTemplateDir = FileNameJoin[{ParentDirectory[$flexiblesusyMetaDir], "templates"}];

FS`Version = StringTrim[FSImportString[FileNameJoin[{$flexiblesusyConfigDir,"version"}]]];
FS`GitCommit = StringTrim[FSImportString[FileNameJoin[{$flexiblesusyConfigDir,"git_commit"}]]];
FS`Authors = {"P. Athron", "T. Kwasnitza", "D. Harries",
              "J.-h. Park", "T. Steudtner", "D. Stöckinger",
              "A. Voigt", "J. Ziebell"};
FS`Contributors = {};
FS`Years   = "2013-2017";
FS`References = Get[FileNameJoin[{$flexiblesusyConfigDir,"references"}]];

Print[""];
Utils`FSFancyLine["="];
Utils`FSFancyPrint["FlexibleSUSY " <> FS`Version, 0];
Print["  by " <> StringJoin[Riffle[Riffle[FS`Authors, ", "], "\n  ", 11]] <>
      "\n  " <> FS`Years];
If[FS`Contributors =!= {},
   Print["  contributions by " <> Utils`StringJoinWithSeparator[FS`Contributors, ", "]];
  ];
Print[""];
Utils`FSFancyPrint["References:"];
Print["  " <> #]& /@ FS`References;
Print[""];
Utils`FSFancyPrint["Download and Documentation:"];
Print["  https://flexiblesusy.hepforge.org"];
Utils`FSFancyLine["="];
Print[""];

MakeFlexibleSUSY::usage="Creates a spectrum generator given a
 FlexibleSUSY model file (FlexibleSUSY.m).

Example:

  MakeFlexibleSUSY[
      InputFile -> \"models/<model>/FlexibleSUSY.m\",
      OutputDirectory -> \"models/<model>/\",
      DebugOutput -> False];

Options:

  InputFile: The name of the model file.

  OutputDirectory: The output directory for the generated code.

  DebugOutput (True|False): Enable/Disable debug output while running
    the Mathematica meta code.
";

LowPrecision::usage="";
MediumPrecision::usage="";
HighPrecision::usage="";
GUTNormalization::usage="Returns GUT normalization of a given coupling";

BETA::usage = "Head for beta functions"
FSModelName;
FSOutputDir = ""; (* directory for generated code *)
FSLesHouchesList;
FSUnfixedParameters;
EWSBOutputParameters = {};
EWSBInitialGuess = {};
EWSBSubstitutions = {};
SUSYScale;
SUSYScaleFirstGuess;
SUSYScaleInput = {};
SUSYScaleMinimum;
SUSYScaleMaximum;
HighScale;
HighScaleFirstGuess;
HighScaleInput = {};
HighScaleMinimum;
HighScaleMaximum;
LowScale;
LowScaleFirstGuess;
LowScaleInput = {};
LowScaleMinimum;
LowScaleMaximum;
InitialGuessAtLowScale = {};
InitialGuessAtSUSYScale = {};
InitialGuessAtHighScale = {};
OnlyLowEnergyFlexibleSUSY = False;
FlexibleEFTHiggs = False;
SUSYScaleMatching={};
AutomaticInputAtMSUSY = True; (* input unfixed parameters at MSUSY *)
TreeLevelEWSBSolution = {};
Pole;
LowEnergyConstant;
LowEnergyGaugeCoupling;
FSMinimize;
FSFindRoot;
FSSolveEWSBFor;
FSSolveEWSBTreeLevelFor = {};
Temporary;
MZ;
MT;
MZDRbar;
MWDRbar;
MZMSbar;
MWMSbar;
EDRbar;
EMSbar;
ThetaWDRbar;
SCALE;
THRESHOLD;
VEV::usage = "running SM-like VEV in the full model";
UseHiggs2LoopNMSSM = False;
EffectiveMu;
EffectiveMASqr;
UseSM3LoopRGEs = False;
UseMSSM3LoopRGEs = False;
UseMSSMYukawa2LoopSQCD = False;
UseHiggs2LoopSM = False;
UseHiggs3LoopSplit = False;
UseYukawa3LoopQCD = Automatic;
FSRGELoopOrder = 2; (* RGE loop order (0, 1 or 2) *)
PotentialLSPParticles = {};
ExtraSLHAOutputBlocks = {
    {FlexibleSUSYLowEnergy,
        {{1, FlexibleSUSYObservable`aMuon} } },
    {EFFHIGGSCOUPLINGS, NoScale,
        {{1, FlexibleSUSYObservable`CpHiggsPhotonPhoton},
         {2, FlexibleSUSYObservable`CpHiggsGluonGluon},
         {3, FlexibleSUSYObservable`CpPseudoScalarPhotonPhoton},
         {4, FlexibleSUSYObservable`CpPseudoScalarGluonGluon} } },
};
FSExtraInputParameters = {};
FSAuxiliaryParameterInfo = {};
IMMINPAR = {};
IMEXTPAR = {};

(* Standard Model input parameters (SLHA input parameters) *)
(* {parameter, {"block", entry}, type}                     *)
SMINPUTS = {
    {AlphaEMInvInput    , {"SMINPUTS",  1}, CConversion`ScalarType[CConversion`realScalarCType]},
    {GFermiInput        , {"SMINPUTS",  2}, CConversion`ScalarType[CConversion`realScalarCType]},
    {AlphaSInput        , {"SMINPUTS",  3}, CConversion`ScalarType[CConversion`realScalarCType]},
    {MZPoleInput        , {"SMINPUTS",  4}, CConversion`ScalarType[CConversion`realScalarCType]},
    {MBottomMbottomInput, {"SMINPUTS",  5}, CConversion`ScalarType[CConversion`realScalarCType]},
    {MTopPoleInput      , {"SMINPUTS",  6}, CConversion`ScalarType[CConversion`realScalarCType]},
    {MTauPoleInput      , {"SMINPUTS",  7}, CConversion`ScalarType[CConversion`realScalarCType]},
    {MNeutrino3PoleInput, {"SMINPUTS",  8}, CConversion`ScalarType[CConversion`realScalarCType]},
    {MWPoleInput        , {"SMINPUTS", 10}, CConversion`ScalarType[CConversion`realScalarCType]},
    {MElectronPoleInput , {"SMINPUTS", 11}, CConversion`ScalarType[CConversion`realScalarCType]},
    {MNeutrino1PoleInput, {"SMINPUTS", 12}, CConversion`ScalarType[CConversion`realScalarCType]},
    {MMuonPoleInput     , {"SMINPUTS", 13}, CConversion`ScalarType[CConversion`realScalarCType]},
    {MNeutrino2PoleInput, {"SMINPUTS", 14}, CConversion`ScalarType[CConversion`realScalarCType]},
    {MDown2GeVInput     , {"SMINPUTS", 21}, CConversion`ScalarType[CConversion`realScalarCType]},
    {MUp2GeVInput       , {"SMINPUTS", 22}, CConversion`ScalarType[CConversion`realScalarCType]},
    {MStrange2GeVInput  , {"SMINPUTS", 23}, CConversion`ScalarType[CConversion`realScalarCType]},
    {MCharmMCharm       , {"SMINPUTS", 24}, CConversion`ScalarType[CConversion`realScalarCType]}
};

(* renormalization schemes *)
DRbar;
MSbar;
FSRenormalizationScheme = DRbar;

(* all model parameters are real by default *)
SARAH`RealParameters = { All };

(* precision of pole mass calculation *)
DefaultPoleMassPrecision = MediumPrecision;
HighPoleMassPrecision    = {SARAH`HiggsBoson, SARAH`PseudoScalar, SARAH`ChargedHiggs};
MediumPoleMassPrecision  = {};
LowPoleMassPrecision     = {};

FSEigenstates = SARAH`EWSB;
FSSolveEWSBTimeConstraint = 120;
FSSimplifyBetaFunctionsTimeConstraint = 120;
FSSolveWeinbergAngleTimeConstraint = 120;
FSCheckPerturbativityOfDimensionlessParameters = True;
FSPerturbativityThreshold = N[Sqrt[4 Pi]];
FSMaximumExpressionSize = 100;

(* list of masses and parameters to check for convergence

   Example:

   FSConvergenceCheck = {
      M[hh], g3, Yu, Yd[3,3], Ye, B[\[Mu]]
   };
*)
FSConvergenceCheck = Automatic;

(* EWSB solvers *)
GSLHybrid;   (* hybrid method *)
GSLHybridS;  (* hybrid method with dynamic step size *)
GSLBroyden;  (* Broyden method *)
GSLNewton;   (* Newton method *)
FPIRelative; (* Fixed point iteration, convergence crit. relative step size *)
FPIAbsolute; (* Fixed point iteration, convergence crit. absolute step size *)
FPITadpole;  (* Fixed point iteration, convergence crit. relative step size + tadpoles *)
FSEWSBSolvers = { FPIRelative, GSLHybridS, GSLBroyden };

(* BVP solvers *)
TwoScaleSolver;      (* two-scale algorithm *)
LatticeSolver;       (* lattice algorithm *)
SemiAnalyticSolver;  (* semi-analytic algorithm *)
FSBVPSolvers = { TwoScaleSolver };

(* macros *)
IF;
SUM;

(* input value for the calculation of the weak mixing angle *)
FSFermiConstant;
FSMassW;

{FSHiggs, FSHyperchargeCoupling,
 FSLeftCoupling, FSStrongCoupling, FSVEVSM1, FSVEVSM2, FSNeutralino,
 FSChargino, FSNeutralinoMM, FSCharginoMinusMM, FSCharginoPlusMM,
 FSHiggsMM, FSSelectronL, FSSelectronNeutrinoL, FSSmuonL,
 FSSmuonNeutrinoL, FSVectorW, FSVectorZ, FSElectronYukawa};

FSWeakMixingAngleOptions = {
    FlexibleSUSY`FSWeakMixingAngleInput -> FSFermiConstant, (* or FSMassW *)
    FlexibleSUSY`FSWeakMixingAngleExpr  -> ArcSin[Sqrt[1 - Mass[SARAH`VectorW]^2/Mass[SARAH`VectorZ]^2]],
    FlexibleSUSY`FSHiggs                -> SARAH`HiggsBoson,
    FlexibleSUSY`FSHyperchargeCoupling  -> SARAH`hyperchargeCoupling,
    FlexibleSUSY`FSLeftCoupling         -> SARAH`leftCoupling,
    FlexibleSUSY`FSStrongCoupling       -> SARAH`strongCoupling,
    FlexibleSUSY`FSVEVSM1               -> SARAH`VEVSM1,
    FlexibleSUSY`FSVEVSM2               -> SARAH`VEVSM2,
    FlexibleSUSY`FSNeutralino           :> Parameters`GetParticleFromDescription["Neutralinos"],
    FlexibleSUSY`FSChargino             :> Parameters`GetParticleFromDescription["Charginos"],
    FlexibleSUSY`FSNeutralinoMM         -> SARAH`NeutralinoMM,
    FlexibleSUSY`FSCharginoMinusMM      -> SARAH`CharginoMinusMM,
    FlexibleSUSY`FSCharginoPlusMM       -> SARAH`CharginoPlusMM,
    FlexibleSUSY`FSHiggsMM              -> SARAH`HiggsMixingMatrix,
    FlexibleSUSY`FSSelectronL           :> Sum[Susyno`LieGroups`conj[SARAH`SleptonMM[Susyno`LieGroups`i,1]] SARAH`SleptonMM[Susyno`LieGroups`i,1] FlexibleSUSY`M[SARAH`Selectron[Susyno`LieGroups`i]], {Susyno`LieGroups`i,1,TreeMasses`GetDimension[SARAH`Selectron]}],
    FlexibleSUSY`FSSelectronNeutrinoL   :> Sum[Susyno`LieGroups`conj[SARAH`SneutrinoMM[Susyno`LieGroups`i,1]] SARAH`SneutrinoMM[Susyno`LieGroups`i,1] FlexibleSUSY`M[SARAH`Sneutrino[Susyno`LieGroups`i]], {Susyno`LieGroups`i,1,TreeMasses`GetDimension[SARAH`Sneutrino]}],
    FlexibleSUSY`FSSmuonL               :> Sum[Susyno`LieGroups`conj[SARAH`SleptonMM[Susyno`LieGroups`i,2]] SARAH`SleptonMM[Susyno`LieGroups`i,2] FlexibleSUSY`M[SARAH`Selectron[Susyno`LieGroups`i]], {Susyno`LieGroups`i,1,TreeMasses`GetDimension[SARAH`Selectron]}],
    FlexibleSUSY`FSSmuonNeutrinoL       :> Sum[Susyno`LieGroups`conj[SARAH`SneutrinoMM[Susyno`LieGroups`i,2]] SARAH`SneutrinoMM[Susyno`LieGroups`i,2] FlexibleSUSY`M[SARAH`Sneutrino[Susyno`LieGroups`i]], {Susyno`LieGroups`i,1,TreeMasses`GetDimension[SARAH`Sneutrino]}],
    FlexibleSUSY`FSVectorW              -> SARAH`VectorW,
    FlexibleSUSY`FSVectorZ              -> SARAH`VectorZ,
    FlexibleSUSY`FSElectronYukawa       -> SARAH`ElectronYukawa
};

ReadPoleMassPrecisions::ImpreciseHiggs="Warning: Calculating the Higgs pole mass M[`1`] with `2` will lead to an inaccurate result!  Please select MediumPrecision or HighPrecision (recommended) for `1`.";

tadpole::usage="symbolic expression for a tadpole contribution in the
EWSB eqs.  The index corresponds to the ordering of the tadpole
equations in SARAH`TadpoleEquations[] .";

NoScale::usage="placeholder indicating an SLHA block should not
have a scale associated with it.";
CurrentScale::usage="placeholder indicating the current renormalization
scale of the model.";

FSDebugOutput = False;

Begin["`Private`"];

allIndexReplacementRules = {};

GetIndexReplacementRules[] := allIndexReplacementRules;

allBetaFunctions = {};

GetBetaFunctions[] := allBetaFunctions;

allOutputParameters = {};

numberOfModelParameters = 0;

allEWSBSolvers = { GSLHybrid, GSLHybridS, GSLBroyden, GSLNewton,
                   FPIRelative, FPIAbsolute, FPITadpole };

allBVPSolvers = { TwoScaleSolver, LatticeSolver, SemiAnalyticSolver };

HaveEWSBSolver[solver_] := MemberQ[FlexibleSUSY`FSEWSBSolvers, solver];

HaveBVPSolver[solver_] := MemberQ[FlexibleSUSY`FSBVPSolvers, solver];

PrintHeadline[text__] :=
    Block[{},
          Print[""];
          Utils`FSFancyLine[];
          Utils`FSFancyPrint[text];
          Utils`FSFancyLine[];
         ];

DecomposeVersionString[version_String] :=
    ToExpression /@ StringSplit[version, "."];

ToVersionString[{major_Integer, minor_Integer, patch_Integer}] :=
    ToString[major] <> "." <> ToString[minor] <> "." <> ToString[patch];

DebugPrint[msg___] :=
    If[FlexibleSUSY`FSDebugOutput,
       Print["Debug<FlexibleSUSY>: ", Sequence @@ InputFormOfNonStrings /@ {msg}]];

CheckSARAHVersion[] :=
    Module[{minimRequired, minimRequiredVersionFile, sarahVersion},
           Print["Checking SARAH version ..."];
           minimRequiredVersionFile = FileNameJoin[{$flexiblesusyConfigDir,
                                                    "required_sarah_version.m"}];
           (* reading minimum required SARAH version from config file *)
           minimRequired = Get[minimRequiredVersionFile];
           If[minimRequired === $Failed,
              Print["Error: Cannot read required SARAH version from file ",
                    minimRequiredVersionFile];
              Print["   Did you run configure?"];
              Quit[1];
             ];
           sarahVersion = DecomposeVersionString[SA`Version];
           If[sarahVersion[[1]] < minimRequired[[1]] ||
              (sarahVersion[[1]] == minimRequired[[1]] &&
               sarahVersion[[2]] < minimRequired[[2]]) ||
              (sarahVersion[[1]] == minimRequired[[1]] &&
               sarahVersion[[2]] == minimRequired[[2]] &&
               sarahVersion[[3]] < minimRequired[[3]]),
              Print["Error: SARAH version ", SA`Version, " no longer supported!"];
              Print["Please use version ", ToVersionString[minimRequired],
                    " or higher"];
              Quit[1];
             ];
          ];

CheckFermiConstantInputRequirements[requiredSymbols_List, printout_:True] :=
    Module[{resolvedSymbols, symbols, areDefined, availPars},
           resolvedSymbols = requiredSymbols /. FlexibleSUSY`FSWeakMixingAngleOptions;
           resolvedSymbols = resolvedSymbols /. {
               a_[idx__] :> a /; And @@ (NumberQ /@ {idx})
           };
           symbols = DeleteDuplicates[Cases[resolvedSymbols, _Symbol, {0,Infinity}]];
           availPars = Join[TreeMasses`GetParticles[],
                            Parameters`GetInputParameters[],
                            Parameters`GetModelParameters[],
                            Parameters`GetOutputParameters[]];
           areDefined = MemberQ[availPars, #]& /@ symbols;
           If[printout,
              Print["Unknown symbol: ", #]& /@
              Cases[Utils`Zip[areDefined, symbols], {False, p_} :> p];
             ];
           And @@ areDefined
          ];

CheckFermiConstantInputRequirementsForSUSYModel[] :=
    CheckFermiConstantInputRequirements[
        {FSHiggs, FSHyperchargeCoupling,
         FSLeftCoupling, FSStrongCoupling, FSVEVSM1, FSVEVSM2,
         FSNeutralino, FSChargino, FSNeutralinoMM, FSCharginoMinusMM,
         FSCharginoPlusMM, FSHiggsMM, FSSelectronL, FSSelectronNeutrinoL,
         FSSmuonL, FSSmuonNeutrinoL, FSVectorW, FSVectorZ,
         FSElectronYukawa}
    ];

CheckFermiConstantInputRequirementsForNonSUSYModel[] :=
    CheckFermiConstantInputRequirements[
        {FSHiggs, FSHyperchargeCoupling,
         FSLeftCoupling, FSStrongCoupling, FSVectorW, FSVectorZ,
         FSElectronYukawa}
    ];

CheckWeakMixingAngleInputRequirements[input_] :=
    Switch[input,
           FlexibleSUSY`FSFermiConstant,
               Switch[SARAH`SupersymmetricModel,
                      True,
                          If[CheckFermiConstantInputRequirementsForSUSYModel[],
                             input
                             ,
                             Print["Error: cannot use ", input, " because model"
                                   " requirements are not fulfilled"];
                             Print["   Using default input: ", FlexibleSUSY`FSMassW];
                             FlexibleSUSY`FSMassW
                          ],
                      False,
                          If[CheckFermiConstantInputRequirementsForNonSUSYModel[],
                             input
                             ,
                             Print["Error: cannot use ", input, " because model"
                                   " requirements are not fulfilled"];
                             Print["   Using default input: ", FlexibleSUSY`FSMassW];
                             FlexibleSUSY`FSMassW
                          ],
                      _,
                          Print["Error: model type: ", SARAH`SupersymmetricModel];
                          Print["   Using default input: ", FlexibleSUSY`FSMassW];
                          FlexibleSUSY`FSMassW
               ],
           FlexibleSUSY`FSMassW,
               input,
           _,
               Print["Error: unknown input ", input];
               Print["   Using default input: ", FlexibleSUSY`FSMassW];
               FlexibleSUSY`FSMassW
          ];

CheckEWSBSolvers[solvers_List] :=
    Module[{invalidSolvers},
           invalidSolvers = Complement[solvers, allEWSBSolvers];
           If[invalidSolvers =!= {},
              Print["Error: invalid EWSB solvers requested: ", invalidSolvers];
              Quit[1];
             ];
          ];

CheckBVPSolvers[solvers_List] :=
    Module[{invalidSolvers},
           invalidSolvers = Complement[solvers, allBVPSolvers];
           If[invalidSolvers =!= {},
              Print["Error: invalid BVP solvers requested: ", invalidSolvers];
              Quit[1];
             ];
          ];

CheckModelFileSettings[] :=
    Module[{},
           (* FlexibleSUSY model name *)
           If[!ValueQ[FlexibleSUSY`FSModelName] || Head[FlexibleSUSY`FSModelName] =!= String,
              Print["Warning: FlexibleSUSY`FSModelName not defined!",
                    " I'm using Model`Name from SARAH: ", Model`Name];
              FlexibleSUSY`FSModelName = Model`Name;
             ];
           (* Set OnlyLowEnergyFlexibleSUSY to False by default *)
           If[!ValueQ[FlexibleSUSY`OnlyLowEnergyFlexibleSUSY] ||
              (FlexibleSUSY`OnlyLowEnergyFlexibleSUSY =!= True &&
               FlexibleSUSY`OnlyLowEnergyFlexibleSUSY =!= False),
              FlexibleSUSY`OnlyLowEnergyFlexibleSUSY = False;
             ];
           If[Head[FlexibleSUSY`InitialGuessAtLowScale] =!= List,
              FlexibleSUSY`InitialGuessAtLowScale = {};
             ];
           If[Head[FlexibleSUSY`InitialGuessAtSUSYScale] =!= List,
              FlexibleSUSY`InitialGuessAtSUSYScale = {};
             ];
           If[Head[FlexibleSUSY`InitialGuessAtHighScale] =!= List,
              FlexibleSUSY`InitialGuessAtHighScale = {};
             ];
           (* HighScale *)
           If[!ValueQ[FlexibleSUSY`HighScale],
              If[!FlexibleSUSY`OnlyLowEnergyFlexibleSUSY,
                 Print["Warning: FlexibleSUSY`HighScale should be",
                       " set in the model file!"];
                ];
              FlexibleSUSY`HighScale := 2 10^16;
             ];
           If[!ValueQ[FlexibleSUSY`HighScaleFirstGuess],
              If[!FlexibleSUSY`OnlyLowEnergyFlexibleSUSY,
                 Print["Warning: FlexibleSUSY`HighScaleFirstGuess should be",
                       " set in the model file!"];
                ];
              FlexibleSUSY`HighScaleFirstGuess = 2.0 10^16;
             ];
           If[Head[FlexibleSUSY`HighScaleInput] =!= List,
              FlexibleSUSY`HighScaleInput = {};
             ];
           (* LowScale *)
           If[!ValueQ[FlexibleSUSY`LowScale],
              Print["Warning: FlexibleSUSY`LowScale should be",
                    " set in the model file!"];
              FlexibleSUSY`LowScale := LowEnergyConstant[MZ];
             ];
           If[!ValueQ[FlexibleSUSY`LowScaleFirstGuess],
              Print["Warning: FlexibleSUSY`LowScaleFirstGuess should be",
                    " set in the model file!"];
              FlexibleSUSY`LowScaleFirstGuess = LowEnergyConstant[MZ];
             ];
           If[Head[FlexibleSUSY`LowScaleInput] =!= List,
              FlexibleSUSY`LowScaleInput = {};
             ];
           (* SUSYScale *)
           If[!ValueQ[FlexibleSUSY`SUSYScale],
              Print["Warning: FlexibleSUSY`SUSYScale should be",
                    " set in the model file!"];
              FlexibleSUSY`SUSYScale := 1000;
             ];
           If[!ValueQ[FlexibleSUSY`SUSYScaleFirstGuess],
              Print["Warning: FlexibleSUSY`SUSYScaleFirstGuess should be",
                    " set in the model file!"];
              FlexibleSUSY`SUSYScaleFirstGuess = 1000;
             ];
           If[Head[FlexibleSUSY`SUSYScaleInput] =!= List,
              FlexibleSUSY`SUSYScaleInput = {};
             ];

           If[Head[SARAH`MINPAR] =!= List,
              SARAH`MINPAR = {};
             ];
           If[Head[SARAH`EXTPAR] =!= List,
              SARAH`EXTPAR = {};
             ];
           If[Head[IMMINPAR] =!= List,
              IMMINPAR = {};
             ];
           If[Head[IMEXTPAR] =!= List,
              IMEXTPAR = {};
             ];
           If[Head[FlexibleSUSY`TreeLevelEWSBSolution] =!= List,
              FlexibleSUSY`TreeLevelEWSBSolution = {};
             ];
           If[Head[FlexibleSUSY`ExtraSLHAOutputBlocks] =!= List,
              FlexibleSUSY`ExtraSLHAOutputBlocks = {};
             ];
           If[Head[FlexibleSUSY`EWSBOutputParameters] =!= List,
              Print["Error: EWSBOutputParameters has to be set to a list",
                    " of model parameters chosen to be output of the EWSB eqs."];
              Quit[1];
             ];
           If[Head[FlexibleSUSY`EWSBInitialGuess] =!= List,
              FlexibleSUSY`EWSBInitialGuess = {};
             ];
           If[Head[FlexibleSUSY`EWSBSubstitutions] =!= List,
              FlexibleSUSY`EWSBSubstitutions = {};
             ];
           If[ValueQ[FlexibleSUSY`FSExtraInputParameters],
              Print["Error: the use of FSExtraInputParameters is no longer supported!"];
              Print["   Please add the entries in FSExtraInputParameters to"];
              Print["   the parameters defined in FSAuxiliaryParameterInfo."];
              Quit[1];
             ];
           If[Head[FlexibleSUSY`FSAuxiliaryParameterInfo] =!= List,
              Print["Error: FSAuxiliaryParameterInfo has to be set to a list!"];
              Quit[1];
              ,
              If[!(And @@ (MatchQ[#,{_, {__}}]& /@ FlexibleSUSY`FSAuxiliaryParameterInfo)),
                 Print["Error: FSAuxiliaryParameterInfo must be of the form",
                       " {{par, {property -> value, ...}}, ... }"];
                ];
             ];
           CheckEWSBSolvers[FlexibleSUSY`FSEWSBSolvers];
           CheckBVPSolvers[FlexibleSUSY`FSBVPSolvers];
          ];

CheckExtraParametersUsage[parameters_List, boundaryConditions_List] :=
    Module[{usedCases, multiplyUsedPars},
           usedCases = Function[par, !FreeQ[#, par]& /@ boundaryConditions] /@ parameters;
           multiplyUsedPars = Position[Count[#, True]& /@ usedCases, n_ /; n > 1];
           If[multiplyUsedPars =!= {},
              Print["Warning: the following auxiliary parameters appear at"];
              Print["   multiple scales, but do not run:"];
              Print["  ", Extract[parameters, multiplyUsedPars]];
             ];
          ];

ReplaceIndicesInUserInput[rules_] :=
    Block[{},
          FlexibleSUSY`InitialGuessAtLowScale  = FlexibleSUSY`InitialGuessAtLowScale  /. rules;
          FlexibleSUSY`InitialGuessAtSUSYScale = FlexibleSUSY`InitialGuessAtSUSYScale /. rules;
          FlexibleSUSY`InitialGuessAtHighScale = FlexibleSUSY`InitialGuessAtHighScale /. rules;
          FlexibleSUSY`HighScale               = FlexibleSUSY`HighScale               /. rules;
          FlexibleSUSY`HighScaleFirstGuess     = FlexibleSUSY`HighScaleFirstGuess     /. rules;
          FlexibleSUSY`HighScaleInput          = FlexibleSUSY`HighScaleInput          /. rules;
          FlexibleSUSY`LowScale                = FlexibleSUSY`LowScale                /. rules;
          FlexibleSUSY`LowScaleFirstGuess      = FlexibleSUSY`LowScaleFirstGuess      /. rules;
          FlexibleSUSY`LowScaleInput           = FlexibleSUSY`LowScaleInput           /. rules;
          FlexibleSUSY`SUSYScale               = FlexibleSUSY`SUSYScale               /. rules;
          FlexibleSUSY`SUSYScaleFirstGuess     = FlexibleSUSY`SUSYScaleFirstGuess     /. rules;
          FlexibleSUSY`SUSYScaleInput          = FlexibleSUSY`SUSYScaleInput          /. rules;
         ];

EvaluateUserInput[] :=
    Block[{},
          FlexibleSUSY`HighScaleInput          = Map[Evaluate, FlexibleSUSY`HighScaleInput, {0,Infinity}];
          FlexibleSUSY`LowScaleInput           = Map[Evaluate, FlexibleSUSY`LowScaleInput , {0,Infinity}];
          FlexibleSUSY`SUSYScaleInput          = Map[Evaluate, FlexibleSUSY`SUSYScaleInput, {0,Infinity}];
         ];

GUTNormalization[coupling_] :=
    Parameters`GetGUTNormalization[coupling];

ParticleIndexRule[par_, name_String] := {
    "@" <> name <> "@" -> CConversion`ToValidCSymbolString[par],
    "@" <> name <> "_" ~~ num___ ~~ "@" /; StringFreeQ[num, "@"] :>
    CConversion`ToValidCSymbolString[par] <> If[TreeMasses`GetDimension[par] > 1, "(" <> num <> ")", ""],
    "@" <> name <> "(" ~~ num___ ~~ ")@" /; StringFreeQ[num, "@"] :>
    CConversion`ToValidCSymbolString[par] <> If[TreeMasses`GetDimension[par] > 1, "(" <> num <> ")", "()"]
};

GenerationIndexRule[par_, name_String] :=
    "@Generations(" ~~ name ~~ ")@" :>
    ToString[TreeMasses`GetDimension[par]];

GeneralReplacementRules[] :=
    Join[
    ParticleIndexRule[SARAH`VectorZ, "VectorZ"],
    ParticleIndexRule[SARAH`VectorW, "VectorW"],
    ParticleIndexRule[SARAH`VectorP, "VectorP"],
    ParticleIndexRule[SARAH`VectorG, "VectorG"],
    ParticleIndexRule[SARAH`TopQuark, "TopQuark"],
    ParticleIndexRule[SARAH`BottomQuark, "BottomQuark"],
    ParticleIndexRule[SARAH`Electron, "Electron"],
    ParticleIndexRule[SARAH`Neutrino, "Neutrino"],
    ParticleIndexRule[SARAH`HiggsBoson, "HiggsBoson"],
    ParticleIndexRule[SARAH`PseudoScalarBoson, "PseudoScalarBoson"],
    ParticleIndexRule[SARAH`ChargedHiggs, "ChargedHiggs"],
    ParticleIndexRule[SARAH`TopSquark, "TopSquark"],
    ParticleIndexRule[SARAH`BottomSquark, "BottomSquark"],
    ParticleIndexRule[SARAH`Sneutrino, "Sneutrino"],
    ParticleIndexRule[SARAH`Selectron, "Selectron"],
    ParticleIndexRule[SARAH`Gluino, "Gluino"],
    {
        GenerationIndexRule[SARAH`VectorZ, "VectorZ"],
        GenerationIndexRule[SARAH`VectorW, "VectorW"],
        GenerationIndexRule[SARAH`VectorP, "VectorP"],
        GenerationIndexRule[SARAH`VectorG, "VectorG"],
        GenerationIndexRule[SARAH`TopQuark, "TopQuark"],
        GenerationIndexRule[SARAH`BottomQuark, "BottomQuark"],
        GenerationIndexRule[SARAH`Electron, "Electron"],
        GenerationIndexRule[SARAH`Neutrino, "Neutrino"],
        GenerationIndexRule[SARAH`HiggsBoson, "HiggsBoson"],
        GenerationIndexRule[SARAH`PseudoScalarBoson, "PseudoScalarBoson"],
        GenerationIndexRule[SARAH`ChargedHiggs, "ChargedHiggs"],
        GenerationIndexRule[SARAH`TopSquark, "TopSquark"],
        GenerationIndexRule[SARAH`BottomSquark, "BottomSquark"],
        GenerationIndexRule[SARAH`Sneutrino, "Sneutrino"],
        GenerationIndexRule[SARAH`Selectron, "Selectron"],
        GenerationIndexRule[SARAH`Gluino, "Gluino"]
    },
    { "@UpYukawa@"       -> CConversion`ToValidCSymbolString[SARAH`UpYukawa],
      "@DownYukawa@"     -> CConversion`ToValidCSymbolString[SARAH`DownYukawa],
      "@ElectronYukawa@" -> CConversion`ToValidCSymbolString[SARAH`ElectronYukawa],
      "@LeftUpMixingMatrix@"   -> CConversion`ToValidCSymbolString[SARAH`UpMatrixL],
      "@LeftDownMixingMatrix@" -> CConversion`ToValidCSymbolString[SARAH`DownMatrixL],
      "@RightUpMixingMatrix@"  -> CConversion`ToValidCSymbolString[SARAH`UpMatrixR],
      "@RightDownMixingMatrix@"-> CConversion`ToValidCSymbolString[SARAH`DownMatrixR],
      "@hyperchargeCoupling@" -> CConversion`ToValidCSymbolString[SARAH`hyperchargeCoupling],
      "@leftCoupling@"        -> CConversion`ToValidCSymbolString[SARAH`leftCoupling],
      "@strongCoupling@"      -> CConversion`ToValidCSymbolString[SARAH`strongCoupling],
      "@hyperchargeCouplingGutNormalization@"  -> CConversion`RValueToCFormString[Parameters`GetGUTNormalization[SARAH`hyperchargeCoupling]],
      "@leftCouplingGutNormalization@"  -> CConversion`RValueToCFormString[Parameters`GetGUTNormalization[SARAH`leftCoupling]],
      "@hyperchargeCouplingInverseGutNormalization@" -> CConversion`RValueToCFormString[1/Parameters`GetGUTNormalization[SARAH`hyperchargeCoupling]],
      "@leftCouplingInverseGutNormalization@" -> CConversion`RValueToCFormString[1/Parameters`GetGUTNormalization[SARAH`leftCoupling]],
      "@perturbativityThreshold@" -> ToString[N[FlexibleSUSY`FSPerturbativityThreshold]],
      "@ModelName@"           -> FlexibleSUSY`FSModelName,
      "@numberOfModelParameters@" -> ToString[numberOfModelParameters],
      "@numberOfParticles@"    -> ToString[Length @ GetLoopCorrectedParticles[FlexibleSUSY`FSEigenstates]],
      "@numberOfSMParticles@"  -> ToString[Length @ Select[GetLoopCorrectedParticles[FlexibleSUSY`FSEigenstates], TreeMasses`IsSMParticle]],
      "@numberOfBSMParticles@" -> ToString[Length @ Complement[GetLoopCorrectedParticles[FlexibleSUSY`FSEigenstates],
                                                               Select[GetLoopCorrectedParticles[FlexibleSUSY`FSEigenstates], TreeMasses`IsSMParticle]]],
      "@InputParameter_" ~~ num_ ~~ "@" /; IntegerQ[ToExpression[num]] :> CConversion`ToValidCSymbolString[
          If[Parameters`GetInputParameters[] === {},
             "",
             Parameters`GetInputParameters[][[ToExpression[num]]]
            ]
      ],
      "@setInputParameterTo[" ~~ num_ ~~ "," ~~ value__ ~~ "]@" /; IntegerQ[ToExpression[num]] :>
          If[Parameters`GetInputParameters[] === {},
             "",
             IndentText[IndentText[
                 Parameters`SetInputParameter[
                     Parameters`GetInputParameters[][[ToExpression[num]]],
                     value,
                     "INPUTPARAMETER"
                 ]
             ]]
            ],
      "@RenScheme@"           -> ToString[FlexibleSUSY`FSRenormalizationScheme],
      "@ModelTypes@"          -> FlexibleTower`GetModelTypes[],
      "@DateAndTime@"         -> DateString[],
      "@SARAHVersion@"        -> SA`Version,
      "@FlexibleSUSYVersion@" -> FS`Version,
      "@FlexibleSUSYGitCommit@" -> FS`GitCommit
    }
    ];


WriteRGEClass[betaFun_List, anomDim_List, files_List,
              templateFile_String, makefileModuleTemplates_List,
              additionalTraces_List:{}, numberOfBaseClassParameters_:0] :=
   Module[{beta, setter, getter, parameterDef, set,
           display,
           cCtorParameterList, parameterCopyInit, betaParameterList,
           anomDimPrototypes, anomDimFunctions, printParameters, parameters,
           numberOfParameters, clearParameters,
           singleBetaFunctionsDecls, singleBetaFunctionsDefsFiles,
           traceDefs, calcTraces, sarahTraces},
          (* extract list of parameters from the beta functions *)
          parameters = BetaFunction`GetName[#]& /@ betaFun;
          (* count number of parameters *)
          numberOfParameters = BetaFunction`CountNumberOfParameters[betaFun] + numberOfBaseClassParameters;
          (* create C++ functions and parameter declarations *)
          sarahTraces          = Traces`ConvertSARAHTraces[additionalTraces];
          beta                 = BetaFunction`CreateBetaFunction[betaFun];
          setter               = BetaFunction`CreateSetters[betaFun];
          getter               = BetaFunction`CreateGetters[betaFun];
          parameterDef         = BetaFunction`CreateParameterDefinitions[betaFun];
          set                  = BetaFunction`CreateSetFunction[betaFun, numberOfBaseClassParameters];
          display              = BetaFunction`CreateDisplayFunction[betaFun, numberOfBaseClassParameters];
          cCtorParameterList   = BetaFunction`CreateCCtorParameterList[betaFun];
          parameterCopyInit    = BetaFunction`CreateCCtorInitialization[betaFun];
          betaParameterList    = BetaFunction`CreateParameterList[betaFun, "beta_"];
          clearParameters      = BetaFunction`ClearParameters[betaFun];
          anomDimPrototypes    = AnomalousDimension`CreateAnomDimPrototypes[anomDim];
          anomDimFunctions     = AnomalousDimension`CreateAnomDimFunctions[anomDim];
          printParameters      = WriteOut`PrintParameters[parameters, "ostr"];
          singleBetaFunctionsDecls = BetaFunction`CreateSingleBetaFunctionDecl[betaFun];
          traceDefs            = Traces`CreateTraceDefs[betaFun];
          traceDefs            = traceDefs <> Traces`CreateSARAHTraceDefs[sarahTraces];
          calcTraces           = {Traces`CreateSARAHTraceCalculation[sarahTraces, "TRACE_STRUCT"],
                                  Sequence @@ Traces`CreateTraceCalculation[betaFun, "TRACE_STRUCT"] };
          WriteOut`ReplaceInFiles[files,
                 { "@beta@"                 -> IndentText[WrapLines[beta]],
                   "@clearParameters@"      -> IndentText[WrapLines[clearParameters]],
                   "@display@"              -> IndentText[display],
                   "@set@"                  -> IndentText[set],
                   "@cCtorParameterList@"   -> WrapLines[cCtorParameterList],
                   "@parameterCopyInit@"    -> WrapLines[parameterCopyInit],
                   "@betaParameterList@"    -> betaParameterList,
                   "@parameterDef@"         -> IndentText[parameterDef],
                   "@cCtorParameterList@"   -> WrapLines[cCtorParameterList],
                   "@setter@"               -> IndentText[setter],
                   "@getter@"               -> IndentText[getter],
                   "@anomDimPrototypes@"    -> IndentText[anomDimPrototypes],
                   "@anomDimFunctions@"     -> WrapLines[anomDimFunctions],
                   "@numberOfParameters@"   -> RValueToCFormString[numberOfParameters],
                   "@printParameters@"      -> IndentText[printParameters],
                   "@singleBetaFunctionsDecls@" -> IndentText[singleBetaFunctionsDecls],
                   "@traceDefs@"            -> IndentText[IndentText[traceDefs]],
                   "@calc1LTraces@"         -> IndentText @ IndentText[WrapLines[calcTraces[[1]] <> "\n" <> calcTraces[[2]]]],
                   "@calc2LTraces@"         -> IndentText @ IndentText[WrapLines[calcTraces[[3]]]],
                   "@calc3LTraces@"         -> IndentText @ IndentText[WrapLines[calcTraces[[4]]]],
                   Sequence @@ GeneralReplacementRules[]
                 } ];
          singleBetaFunctionsDefsFiles = BetaFunction`CreateSingleBetaFunctionDefs[betaFun, templateFile, sarahTraces];
          Print["Creating makefile module for the beta functions ..."];
          WriteMakefileModule[singleBetaFunctionsDefsFiles,
                              makefileModuleTemplates];
         ];

WriteInputParameterClass[inputParameters_List, files_List] :=
   Module[{defineInputParameters, printInputParameters, get, set, inputPars},
          inputPars = {First[#], #[[3]]}& /@ inputParameters;
          defineInputParameters = Constraint`DefineInputParameters[inputPars];
          printInputParameters = WriteOut`PrintInputParameters[inputPars,"ostr"];
          get = Parameters`CreateInputParameterArrayGetter[inputPars];
          set = Parameters`CreateInputParameterArraySetter[inputPars];
          WriteOut`ReplaceInFiles[files,
                         { "@defineInputParameters@" -> IndentText[defineInputParameters],
                           "@printInputParameters@"       -> IndentText[printInputParameters],
                           "@get@"                        -> IndentText[get],
                           "@set@"                        -> IndentText[set],
                           Sequence @@ GeneralReplacementRules[]
                         } ];
          ];

WriteConstraintClass[condition_, settings_List, scaleFirstGuess_,
                     {minimumScale_, maximumScale_}, files_List] :=
   Module[{applyConstraint = "", calculateScale, scaleGuess,
           restrictScale,
           temporarySetting = "",
           setDRbarYukawaCouplings,
           calculateDRbarMasses,
           calculateDeltaAlphaEm, calculateDeltaAlphaS,
           calculateGaugeCouplings,
           calculateThetaW,
           recalculateMWPole,
           checkPerturbativityForDimensionlessParameters = ""},
          Constraint`SetBetaFunctions[GetBetaFunctions[]];
          applyConstraint = Constraint`ApplyConstraints[settings];
          calculateScale  = Constraint`CalculateScale[condition, "scale"];
          scaleGuess      = Constraint`CalculateScale[scaleFirstGuess, "initial_scale_guess"];
          restrictScale   = Constraint`RestrictScale[{minimumScale, maximumScale}];
          temporarySetting   = Constraint`SetTemporarily[settings];
          calculateDeltaAlphaEm   = ThresholdCorrections`CalculateDeltaAlphaEm[FlexibleSUSY`FSRenormalizationScheme];
          calculateDeltaAlphaS    = ThresholdCorrections`CalculateDeltaAlphaS[FlexibleSUSY`FSRenormalizationScheme];
          calculateThetaW         = ThresholdCorrections`CalculateThetaW[FSWeakMixingAngleOptions,SARAH`SupersymmetricModel];
          calculateGaugeCouplings = ThresholdCorrections`CalculateGaugeCouplings[];
          recalculateMWPole       = ThresholdCorrections`RecalculateMWPole[FSWeakMixingAngleOptions];
          setDRbarYukawaCouplings = {
              ThresholdCorrections`SetDRbarYukawaCouplingTop[settings],
              ThresholdCorrections`SetDRbarYukawaCouplingBottom[settings],
              ThresholdCorrections`SetDRbarYukawaCouplingElectron[settings]
          };
          calculateDRbarMasses = {
              LoopMasses`CallCalculateDRbarMass["Up Quark"         , "Up-Quarks"  , 1, "upQuarksDRbar", "qedqcd.displayMass(softsusy::mUp)"      ],
              LoopMasses`CallCalculateDRbarMass["Charmed Quark"    , "Up-Quarks"  , 2, "upQuarksDRbar", "qedqcd.displayMass(softsusy::mCharm)"   ],
              LoopMasses`CallCalculateDRbarMass["Top Quark"        , "Up-Quarks"  , 3, "upQuarksDRbar", "qedqcd.displayPoleMt()"                 ],
              LoopMasses`CallCalculateDRbarMass["Down Quark"       , "Down-Quarks", 1, "downQuarksDRbar", "qedqcd.displayMass(softsusy::mDown)"    ],
              LoopMasses`CallCalculateDRbarMass["Strange Quark"    , "Down-Quarks", 2, "downQuarksDRbar", "qedqcd.displayMass(softsusy::mStrange)" ],
              LoopMasses`CallCalculateDRbarMass["Bottom Quark"     , "Down-Quarks", 3, "downQuarksDRbar", "qedqcd.displayMass(softsusy::mBottom)"  ],
              LoopMasses`CallCalculateDRbarMass["Electron"         , "Leptons"    , 1, "downLeptonsDRbar", "qedqcd.displayMass(softsusy::mElectron)"],
              LoopMasses`CallCalculateDRbarMass["Muon"             , "Leptons"    , 2, "downLeptonsDRbar", "qedqcd.displayMass(softsusy::mMuon)"    ],
              LoopMasses`CallCalculateDRbarMass["Tau"              , "Leptons"    , 3, "downLeptonsDRbar", "qedqcd.displayMass(softsusy::mTau)"     ],
              LoopMasses`CallCalculateDRbarMass["Electron Neutrino", "Neutrinos"  , 1, "neutrinoDRbar", "qedqcd.displayNeutrinoPoleMass(1)"      ],
              LoopMasses`CallCalculateDRbarMass["Muon Neutrino"    , "Neutrinos"  , 2, "neutrinoDRbar", "qedqcd.displayNeutrinoPoleMass(2)"      ],
              LoopMasses`CallCalculateDRbarMass["Tau Neutrino"     , "Neutrinos"  , 3, "neutrinoDRbar", "qedqcd.displayNeutrinoPoleMass(3)"      ]
          };
          If[FSCheckPerturbativityOfDimensionlessParameters,
             checkPerturbativityForDimensionlessParameters =
                 Constraint`CheckPerturbativityForParameters[
                     Parameters`GetModelParametersWithMassDimension[0],
                     FlexibleSUSY`FSPerturbativityThreshold
                 ];
            ];
          WriteOut`ReplaceInFiles[files,
                 { "@applyConstraint@"      -> IndentText[WrapLines[applyConstraint]],
                   "@calculateScale@"       -> IndentText[WrapLines[calculateScale]],
                   "@scaleGuess@"           -> IndentText[WrapLines[scaleGuess]],
                   "@restrictScale@"        -> IndentText[WrapLines[restrictScale]],
                   "@temporarySetting@"     -> IndentText[WrapLines[temporarySetting]],
                   "@calculateGaugeCouplings@" -> IndentText[WrapLines[calculateGaugeCouplings]],
                   "@calculateDeltaAlphaEm@" -> IndentText[WrapLines[calculateDeltaAlphaEm]],
                   "@calculateDeltaAlphaS@"  -> IndentText[WrapLines[calculateDeltaAlphaS]],
                   "@calculateThetaW@"       -> IndentText[WrapLines[calculateThetaW]],
                   "@recalculateMWPole@"     -> IndentText[WrapLines[recalculateMWPole]],
                   "@calculateDRbarMassUp@"      -> IndentText[IndentText[calculateDRbarMasses[[1]]]],
                   "@calculateDRbarMassCharm@"   -> IndentText[IndentText[calculateDRbarMasses[[2]]]],
                   "@calculateDRbarMassTop@"     -> IndentText[IndentText[calculateDRbarMasses[[3]]]],
                   "@calculateDRbarMassDown@"    -> IndentText[IndentText[calculateDRbarMasses[[4]]]],
                   "@calculateDRbarMassStrange@" -> IndentText[IndentText[calculateDRbarMasses[[5]]]],
                   "@calculateDRbarMassBottom@"  -> IndentText[IndentText[calculateDRbarMasses[[6]]]],
                   "@calculateDRbarMassElectron@"-> IndentText[IndentText[calculateDRbarMasses[[7]]]],
                   "@calculateDRbarMassMuon@"    -> IndentText[IndentText[calculateDRbarMasses[[8]]]],
                   "@calculateDRbarMassTau@"     -> IndentText[IndentText[calculateDRbarMasses[[9]]]],
                   "@calculateDRbarMassElectronNeutrino@"-> IndentText[IndentText[calculateDRbarMasses[[10]]]],
                   "@calculateDRbarMassMuonNeutrino@"    -> IndentText[IndentText[calculateDRbarMasses[[11]]]],
                   "@calculateDRbarMassTauNeutrino@"     -> IndentText[IndentText[calculateDRbarMasses[[12]]]],
                   "@setDRbarUpQuarkYukawaCouplings@"   -> IndentText[WrapLines[setDRbarYukawaCouplings[[1]]]],
                   "@setDRbarDownQuarkYukawaCouplings@" -> IndentText[WrapLines[setDRbarYukawaCouplings[[2]]]],
                   "@setDRbarElectronYukawaCouplings@"  -> IndentText[WrapLines[setDRbarYukawaCouplings[[3]]]],
                   "@checkPerturbativityForDimensionlessParameters@" -> IndentText[checkPerturbativityForDimensionlessParameters],
                   Sequence @@ GeneralReplacementRules[]
                 } ];
          ];

WriteSemiAnalyticConstraintClass[condition_, settings_List, scaleFirstGuess_,
                                 {minimumScale_, maximumScale_},
                                 mustSetSemiAnalyticBCs_, semiAnalyticSolns_List, files_List] :=
   Module[{applyConstraint = "", calculateScale, scaleGuess,
           restrictScale,
           temporarySetting = "", temporaryResetting = "",
           setDRbarYukawaCouplings,
           calculateDRbarMasses,
           calculateDeltaAlphaEm, calculateDeltaAlphaS,
           calculateGaugeCouplings,
           calculateThetaW,
           recalculateMWPole,
           checkPerturbativityForDimensionlessParameters = "",
           semiAnalyticForwardDecls = "",
           semiAnalyticConstraint = "",
           setSemiAnalyticConstraint = "",
           clearSemiAnalyticConstraint = "",
           updateSemiAnalyticConstraint = "",
           saveBoundaryValueParameters = ""},
          Constraint`SetBetaFunctions[GetBetaFunctions[]];
          applyConstraint = Constraint`ApplyConstraints[settings];
          calculateScale  = Constraint`CalculateScale[condition, "scale"];
          scaleGuess      = Constraint`CalculateScale[scaleFirstGuess, "initial_scale_guess"];
          restrictScale   = Constraint`RestrictScale[{minimumScale, maximumScale}];
          temporarySetting   = Constraint`SetTemporarily[settings];
          calculateDeltaAlphaEm   = ThresholdCorrections`CalculateDeltaAlphaEm[FlexibleSUSY`FSRenormalizationScheme];
          calculateDeltaAlphaS    = ThresholdCorrections`CalculateDeltaAlphaS[FlexibleSUSY`FSRenormalizationScheme];
          calculateThetaW         = ThresholdCorrections`CalculateThetaW[FSWeakMixingAngleOptions,SARAH`SupersymmetricModel];
          calculateGaugeCouplings = ThresholdCorrections`CalculateGaugeCouplings[];
          recalculateMWPole       = ThresholdCorrections`RecalculateMWPole[FSWeakMixingAngleOptions];
          setDRbarYukawaCouplings = {
              ThresholdCorrections`SetDRbarYukawaCouplingTop[settings],
              ThresholdCorrections`SetDRbarYukawaCouplingBottom[settings],
              ThresholdCorrections`SetDRbarYukawaCouplingElectron[settings]
          };
          calculateDRbarMasses = {
              LoopMasses`CallCalculateDRbarMass["Up Quark"         , "Up-Quarks"  , 1, "upQuarksDRbar", "qedqcd.displayMass(softsusy::mUp)"      ],
              LoopMasses`CallCalculateDRbarMass["Charmed Quark"    , "Up-Quarks"  , 2, "upQuarksDRbar", "qedqcd.displayMass(softsusy::mCharm)"   ],
              LoopMasses`CallCalculateDRbarMass["Top Quark"        , "Up-Quarks"  , 3, "upQuarksDRbar", "qedqcd.displayPoleMt()"                 ],
              LoopMasses`CallCalculateDRbarMass["Down Quark"       , "Down-Quarks", 1, "downQuarksDRbar", "qedqcd.displayMass(softsusy::mDown)"    ],
              LoopMasses`CallCalculateDRbarMass["Strange Quark"    , "Down-Quarks", 2, "downQuarksDRbar", "qedqcd.displayMass(softsusy::mStrange)" ],
              LoopMasses`CallCalculateDRbarMass["Bottom Quark"     , "Down-Quarks", 3, "downQuarksDRbar", "qedqcd.displayMass(softsusy::mBottom)"  ],
              LoopMasses`CallCalculateDRbarMass["Electron"         , "Leptons"    , 1, "downLeptonsDRbar", "qedqcd.displayMass(softsusy::mElectron)"],
              LoopMasses`CallCalculateDRbarMass["Muon"             , "Leptons"    , 2, "downLeptonsDRbar", "qedqcd.displayMass(softsusy::mMuon)"    ],
              LoopMasses`CallCalculateDRbarMass["Tau"              , "Leptons"    , 3, "downLeptonsDRbar", "qedqcd.displayMass(softsusy::mTau)"     ],
              LoopMasses`CallCalculateDRbarMass["Electron Neutrino", "Neutrinos"  , 1, "neutrinoDRbar", "qedqcd.displayNeutrinoPoleMass(1)"      ],
              LoopMasses`CallCalculateDRbarMass["Muon Neutrino"    , "Neutrinos"  , 2, "neutrinoDRbar", "qedqcd.displayNeutrinoPoleMass(2)"      ],
              LoopMasses`CallCalculateDRbarMass["Tau Neutrino"     , "Neutrinos"  , 3, "neutrinoDRbar", "qedqcd.displayNeutrinoPoleMass(3)"      ]
          };
          If[FSCheckPerturbativityOfDimensionlessParameters,
             checkPerturbativityForDimensionlessParameters =
                 Constraint`CheckPerturbativityForParameters[
                     Parameters`GetModelParametersWithMassDimension[0],
                     FlexibleSUSY`FSPerturbativityThreshold
                 ];
            ];
          If[mustSetSemiAnalyticBCs,
             semiAnalyticForwardDecls = "template <class T>\nclass " <> FlexibleSUSY`FSModelName <> "_soft_parameters_constraint;\n\n";
             semiAnalyticConstraint = FlexibleSUSY`FSModelName <> "_soft_parameters_constraint<Semi_analytic>* soft_constraint{nullptr};\n";
             setSemiAnalyticConstraint = "void set_soft_parameters_constraint(" <> FlexibleSUSY`FSModelName
                                         <> "_soft_parameters_constraint<Semi_analytic>* sc) { soft_constraint = sc; }\n";
             clearSemiAnalyticConstraint = "soft_constraint = nullptr;\n";
             updateSemiAnalyticConstraint = "if (soft_constraint) soft_constraint->set_boundary_scale(scale);\n";
             saveBoundaryValueParameters = SemiAnalytic`SaveBoundaryValueParameters[semiAnalyticSolns];
            ];
          WriteOut`ReplaceInFiles[files,
                 { "@applyConstraint@"      -> IndentText[WrapLines[applyConstraint]],
                   "@calculateScale@"       -> IndentText[WrapLines[calculateScale]],
                   "@scaleGuess@"           -> IndentText[WrapLines[scaleGuess]],
                   "@restrictScale@"        -> IndentText[WrapLines[restrictScale]],
                   "@temporarySetting@"     -> IndentText[WrapLines[temporarySetting]],
                   "@temporaryResetting@"   -> IndentText[WrapLines[temporaryResetting]],
                   "@calculateGaugeCouplings@" -> IndentText[WrapLines[calculateGaugeCouplings]],
                   "@calculateDeltaAlphaEm@" -> IndentText[WrapLines[calculateDeltaAlphaEm]],
                   "@calculateDeltaAlphaS@"  -> IndentText[WrapLines[calculateDeltaAlphaS]],
                   "@calculateThetaW@"       -> IndentText[WrapLines[calculateThetaW]],
                   "@recalculateMWPole@"     -> IndentText[WrapLines[recalculateMWPole]],
                   "@calculateDRbarMassUp@"      -> IndentText[IndentText[calculateDRbarMasses[[1]]]],
                   "@calculateDRbarMassCharm@"   -> IndentText[IndentText[calculateDRbarMasses[[2]]]],
                   "@calculateDRbarMassTop@"     -> IndentText[IndentText[calculateDRbarMasses[[3]]]],
                   "@calculateDRbarMassDown@"    -> IndentText[IndentText[calculateDRbarMasses[[4]]]],
                   "@calculateDRbarMassStrange@" -> IndentText[IndentText[calculateDRbarMasses[[5]]]],
                   "@calculateDRbarMassBottom@"  -> IndentText[IndentText[calculateDRbarMasses[[6]]]],
                   "@calculateDRbarMassElectron@"-> IndentText[IndentText[calculateDRbarMasses[[7]]]],
                   "@calculateDRbarMassMuon@"    -> IndentText[IndentText[calculateDRbarMasses[[8]]]],
                   "@calculateDRbarMassTau@"     -> IndentText[IndentText[calculateDRbarMasses[[9]]]],
                   "@calculateDRbarMassElectronNeutrino@"-> IndentText[IndentText[calculateDRbarMasses[[10]]]],
                   "@calculateDRbarMassMuonNeutrino@"    -> IndentText[IndentText[calculateDRbarMasses[[11]]]],
                   "@calculateDRbarMassTauNeutrino@"     -> IndentText[IndentText[calculateDRbarMasses[[12]]]],
                   "@setDRbarUpQuarkYukawaCouplings@"   -> IndentText[WrapLines[setDRbarYukawaCouplings[[1]]]],
                   "@setDRbarDownQuarkYukawaCouplings@" -> IndentText[WrapLines[setDRbarYukawaCouplings[[2]]]],
                   "@setDRbarElectronYukawaCouplings@"  -> IndentText[WrapLines[setDRbarYukawaCouplings[[3]]]],
                   "@checkPerturbativityForDimensionlessParameters@" -> IndentText[checkPerturbativityForDimensionlessParameters],
                   "@semiAnalyticForwardDecls@" -> semiAnalyticForwardDecls,
                   "@semiAnalyticConstraint@" -> IndentText[semiAnalyticConstraint],
                   "@setSemiAnalyticConstraint@" -> IndentText[setSemiAnalyticConstraint],
                   "@clearSemiAnalyticConstraint@" -> IndentText[clearSemiAnalyticConstraint],
                   "@updateSemiAnalyticConstraint@" -> IndentText[updateSemiAnalyticConstraint],
                   "@saveBoundaryValueParameters@" -> IndentText[WrapLines[saveBoundaryValueParameters]],
                   Sequence @@ GeneralReplacementRules[]
                 } ];
          ];

WriteInitialGuesserClass[lowScaleGuess_List, susyScaleGuess_List, highScaleGuess_List, files_List] :=
   Module[{initialGuessAtLowScale, initialGuessAtLowScaleGaugeCouplings = "",
           initialGuessAtHighScale, setDRbarYukawaCouplings,
           allSettings},
          initialGuessAtLowScale  = Constraint`ApplyConstraints[lowScaleGuess];
          initialGuessAtLowScaleGaugeCouplings = Constraint`InitialGuessAtLowScaleGaugeCouplings[];
          initialGuessAtSUSYScale = Constraint`ApplyConstraints[susyScaleGuess];
          initialGuessAtHighScale = Constraint`ApplyConstraints[highScaleGuess];
          allSettings             = Join[lowScaleGuess, highScaleGuess];
          setDRbarYukawaCouplings = {
              ThresholdCorrections`SetDRbarYukawaCouplingTop[allSettings],
              ThresholdCorrections`SetDRbarYukawaCouplingBottom[allSettings],
              ThresholdCorrections`SetDRbarYukawaCouplingElectron[allSettings]
          };
          WriteOut`ReplaceInFiles[files,
                 { "@initialGuessAtLowScale@"  -> IndentText[WrapLines[initialGuessAtLowScale]],
                   "@initialGuessAtLowScaleGaugeCouplings@" -> IndentText[WrapLines[initialGuessAtLowScaleGaugeCouplings]],
                   "@initialGuessAtSUSYScale@" -> IndentText[WrapLines[initialGuessAtSUSYScale]],
                   "@initialGuessAtHighScale@" -> IndentText[WrapLines[initialGuessAtHighScale]],
                   "@setDRbarUpQuarkYukawaCouplings@"   -> IndentText[WrapLines[setDRbarYukawaCouplings[[1]]]],
                   "@setDRbarDownQuarkYukawaCouplings@" -> IndentText[WrapLines[setDRbarYukawaCouplings[[2]]]],
                   "@setDRbarElectronYukawaCouplings@"  -> IndentText[WrapLines[setDRbarYukawaCouplings[[3]]]],
                   Sequence @@ GeneralReplacementRules[]
                 } ];
          ];

WriteSemiAnalyticInitialGuesserClass[lowScaleGuess_List, susyScaleGuess_List, highScaleGuess_List,
                                     solutionsScale_String, files_List] :=
   Module[{initialGuessAtLowScale, initialGuessAtLowScaleGaugeCouplings = "",
           initialGuessAtHighScale, setDRbarYukawaCouplings,
           allSettings},
          initialGuessAtLowScale  = Constraint`ApplyConstraints[lowScaleGuess];
          initialGuessAtLowScaleGaugeCouplings = Constraint`InitialGuessAtLowScaleGaugeCouplings[];
          initialGuessAtSUSYScale = Constraint`ApplyConstraints[susyScaleGuess];
          initialGuessAtHighScale = Constraint`ApplyConstraints[highScaleGuess];
          allSettings             = Join[lowScaleGuess, highScaleGuess];
          setDRbarYukawaCouplings = {
              ThresholdCorrections`SetDRbarYukawaCouplingTop[allSettings],
              ThresholdCorrections`SetDRbarYukawaCouplingBottom[allSettings],
              ThresholdCorrections`SetDRbarYukawaCouplingElectron[allSettings]
          };
          WriteOut`ReplaceInFiles[files,
                 { "@initialGuessAtLowScale@"  -> IndentText[WrapLines[initialGuessAtLowScale]],
                   "@initialGuessAtLowScaleGaugeCouplings@" -> IndentText[WrapLines[initialGuessAtLowScaleGaugeCouplings]],
                   "@initialGuessAtSUSYScale@" -> IndentText[WrapLines[initialGuessAtSUSYScale]],
                   "@initialGuessAtHighScale@" -> IndentText[WrapLines[initialGuessAtHighScale]],
                   "@setDRbarUpQuarkYukawaCouplings@"   -> IndentText[WrapLines[setDRbarYukawaCouplings[[1]]]],
                   "@setDRbarDownQuarkYukawaCouplings@" -> IndentText[WrapLines[setDRbarYukawaCouplings[[2]]]],
                   "@setDRbarElectronYukawaCouplings@"  -> IndentText[WrapLines[setDRbarYukawaCouplings[[3]]]],
                   "@inputScaleGuess@" -> solutionsScale,
                   Sequence @@ GeneralReplacementRules[]
                 } ];
          ];

WriteConvergenceTesterClass[parameters_, files_List] :=
   Module[{compareFunction},
          compareFunction = ConvergenceTester`CreateCompareFunction[parameters];
          WriteOut`ReplaceInFiles[files,
                 { "@compareFunction@"      -> IndentText[WrapLines[compareFunction]],
                   Sequence @@ GeneralReplacementRules[]
                 } ];
          ];

FindVEV[gauge_] :=
    Module[{result, vev},
           vev = Cases[SARAH`DEFINITION[FlexibleSUSY`FSEigenstates][SARAH`VEVs],
                       {_,{v_,_},{gauge,_},{p_,_},___} | {_,{v_,_},{s_,_},{gauge,_},___} :> v];
           If[vev === {},
              Print["Error: could not find VEV for gauge eigenstate ", gauge];
              Quit[1];
             ];
           vev[[1]]
          ];

GetDimOfVEV[vev_] :=
    Switch[SARAH`getDimParameters[vev],
           {}                         , 1,
           {0}                        , 1,
           {1}                        , 1,
           {idx_}                     , SARAH`getDimParameters[vev][[1]]
          ];

ExpandIndices[sym_, 1] := sym;

ExpandIndices[sym_, number_] :=
    Table[sym[i], {i,1,number}];

ExpandGaugeIndices[gauge_List] :=
    Flatten[ExpandIndices[#, GetDimOfVEV[FindVEV[#]]]& /@ gauge];

ExpandVEVIndices[vev_] :=
    ExpandIndices[vev, GetDimOfVEV[vev]];

(* Returns a list of three-component lists where the information is
   stored which Higgs corresponds to which EWSB eq. and whether the
   corresponding tadpole is real or imaginary (only in models with CP
   violation).

   Example: MRSSM
   In[] := CreateHiggsToEWSBEqAssociation[]
   Out[] = {{hh, 1, Re}, {hh, 2, Re}, {hh, 4, Re}, {hh, 3, Re}}

   This result means:

   EWSB eq. 1 corresponds to hh[1], the 1L tadpole[1] is real
   EWSB eq. 2 corresponds to hh[2], the 1L tadpole[2] is real
   EWSB eq. 3 corresponds to hh[4], the 1L tadpole[3] is real
   EWSB eq. 4 corresponds to hh[3], the 1L tadpole[4] is real
 *)
CreateHiggsToEWSBEqAssociation[] :=
    Module[{vevs},
           vevs = Cases[SARAH`DEFINITION[FlexibleSUSY`FSEigenstates][SARAH`VEVs],
                        {_,{v_,_},{s_,_},{p_,_},___} :> {v,s,p}];
           If[Length[vevs] == 1,
              Return[{{SARAH`HiggsBoson, 1, Re}}];
             ];
           FindPositions[es_] :=
               Module[{gaugeES, higgsGaugeES},
                      gaugeES = ExpandGaugeIndices[es];
                      (* list of gauge eigenstate fields, ordered according to Higgs mixing *)
                      higgsGaugeES = Cases[SARAH`DEFINITION[FlexibleSUSY`FSEigenstates][SARAH`MatterSector],
                                           {gauge_List, {SARAH`HiggsBoson, _}} :> gauge][[1]];
                      higgsGaugeES = ExpandGaugeIndices[higgsGaugeES];
                      (* find positions of gaugeES in higgsGaugeES *)
                      {SARAH`HiggsBoson,#}& /@ (Flatten[Position[higgsGaugeES, #]& /@ gaugeES])
                     ];
           Join[Append[#,Re]& /@ FindPositions[Transpose[vevs][[3]]],
                Append[#,Re]& /@ FindPositions[Transpose[vevs][[2]]]]
          ];

WriteModelSLHAClass[massMatrices_List, files_List] :=
    Module[{k,
            slhaYukawaDef = "",
            slhaYukawaGetter = "",
            convertYukawaCouplingsToSLHA = "",
            slhaTrilinearCouplingsDef = "",
            slhaTrilinearCouplingsGetter = "",
            convertTrilinearCouplingsToSLHA = "",
            slhaSoftSquaredMassesDef = "",
            slhaSoftSquaredMassesGetter = "",
            convertSoftSquaredMassesToSLHA = "",
            slhaFerimonMixingMatricesDef = "",
            slhaFerimonMixingMatricesGetters = "",
            slhaPoleMassGetters = "",
            slhaPoleMixingMatrixGetters = "",
            calculateCKMMatrix = "",
            calculatePMNSMatrix = ""
           },
           slhaYukawaDef        = WriteOut`CreateSLHAYukawaDefinition[];
           slhaYukawaGetter     = WriteOut`CreateSLHAYukawaGetters[];
           convertYukawaCouplingsToSLHA = WriteOut`ConvertYukawaCouplingsToSLHA[];
           slhaTrilinearCouplingsDef    = WriteOut`CreateSLHATrilinearCouplingDefinition[];
           slhaTrilinearCouplingsGetter = WriteOut`CreateSLHATrilinearCouplingGetters[];
           convertTrilinearCouplingsToSLHA = WriteOut`ConvertTrilinearCouplingsToSLHA[];
           slhaSoftSquaredMassesDef    = WriteOut`CreateSLHASoftSquaredMassesDefinition[];
           slhaSoftSquaredMassesGetter = WriteOut`CreateSLHASoftSquaredMassesGetters[];
           convertSoftSquaredMassesToSLHA = WriteOut`ConvertSoftSquaredMassesToSLHA[];
           slhaFerimonMixingMatricesDef = WriteOut`CreateSLHAFermionMixingMatricesDef[];
           slhaFerimonMixingMatricesGetters = WriteOut`CreateSLHAFermionMixingMatricesGetters[];
           calculateCKMMatrix = WriteOut`CalculateCKMMatrix[];
           calculatePMNSMatrix = WriteOut`CalculatePMNSMatrix[];
           For[k = 1, k <= Length[massMatrices], k++,
               slhaPoleMassGetters         = slhaPoleMassGetters <> TreeMasses`CreateSLHAPoleMassGetter[massMatrices[[k]]];
               slhaPoleMixingMatrixGetters = slhaPoleMixingMatrixGetters <> TreeMasses`CreateSLHAPoleMixingMatrixGetter[massMatrices[[k]]];
              ];
           WriteOut`ReplaceInFiles[files,
                          { "@slhaYukawaDef@"                  -> IndentText[slhaYukawaDef],
                            "@slhaYukawaGetter@"               -> IndentText[slhaYukawaGetter],
                            "@convertYukawaCouplingsToSLHA@"   -> IndentText[convertYukawaCouplingsToSLHA],
                            "@slhaFerimonMixingMatricesDef@"   -> IndentText[slhaFerimonMixingMatricesDef],
                            "@slhaFerimonMixingMatricesGetters@" -> IndentText[slhaFerimonMixingMatricesGetters],
                            "@slhaTrilinearCouplingsDef@"      -> IndentText[slhaTrilinearCouplingsDef],
                            "@slhaTrilinearCouplingsGetter@"   -> IndentText[slhaTrilinearCouplingsGetter],
                            "@convertTrilinearCouplingsToSLHA@"-> IndentText[convertTrilinearCouplingsToSLHA],
                            "@slhaSoftSquaredMassesDef@"       -> IndentText[slhaSoftSquaredMassesDef],
                            "@slhaSoftSquaredMassesGetter@"    -> IndentText[slhaSoftSquaredMassesGetter],
                            "@convertSoftSquaredMassesToSLHA@" -> IndentText[convertSoftSquaredMassesToSLHA],
                            "@slhaPoleMassGetters@"            -> IndentText[slhaPoleMassGetters],
                            "@slhaPoleMixingMatrixGetters@"    -> IndentText[slhaPoleMixingMatrixGetters],
                            "@calculateCKMMatrix@"             -> IndentText[calculateCKMMatrix],
                            "@calculatePMNSMatrix@"             -> IndentText[calculatePMNSMatrix],
                            Sequence @@ GeneralReplacementRules[]
                          } ];
          ];

(* Returns a list of three-component lists where the information is
   stored which VEV corresponds to which Tadpole eq.

   Example: MRSSM
   It[] := CreateVEVToTadpoleAssociation[]
   Out[] = {{hh, 1, vd}, {hh, 2, vu}, {hh, 4, vS}, {hh, 3, vT}}
 *)
CreateVEVToTadpoleAssociation[] :=
    Module[{association, vev},
           vevs = Cases[SARAH`DEFINITION[FlexibleSUSY`FSEigenstates][SARAH`VEVs],
                        {_,{v_,_},{s_,_},{p_,_},___} :> {v,s,p}];
           vevs = Flatten @
                  Join[ExpandVEVIndices[FindVEV[#]]& /@ Transpose[vevs][[3]],
                       ExpandVEVIndices[FindVEV[#]]& /@ Transpose[vevs][[2]]];
           association = CreateHiggsToEWSBEqAssociation[];
           {#[[1]], #[[2]], vevs[[#[[2]]]]}& /@ association
          ];

GetRenormalizationScheme[] :=
    If[SARAH`SupersymmetricModel, FlexibleSUSY`DRbar, FlexibleSUSY`MSbar];

WriteFlexibleEFTHiggsMakefileModule[files_List] :=
    Module[{source = "", header = ""},
           If[FlexibleSUSY`FlexibleEFTHiggs === True,
              source = "\t\t" <> FileNameJoin[{FSOutputDir, FlexibleSUSY`FSModelName <> "_standard_model_matching.cpp"}];
              header = "\t\t" <> FileNameJoin[{FSOutputDir, FlexibleSUSY`FSModelName <> "_standard_model_matching.hpp"}];
             ];
           WriteOut`ReplaceInFiles[files,
                  { "@FlexibleEFTHiggsSource@" -> source,
                    "@FlexibleEFTHiggsHeader@" -> header,
                    Sequence @@ GeneralReplacementRules[]
                  } ];
          ];

WriteMatchingClass[susyScaleMatching_List, massMatrices_List, files_List] :=
    Module[{scheme = GetRenormalizationScheme[], userMatching = "",
            alphaS1Lmatching = "", alphaEM1Lmatching = "",
            setBSMParameters = "", higgsMassMatrix,
            setRunningUpQuarkMasses = "", setRunningDownQuarkMasses = "",
            setRunningDownLeptonMasses = "", setYukawas = "",
            calculateMUpQuarkPole1L = "", calculateMDownQuarkPole1L = "",
            calculateMDownLeptonPole1L = "",
            calculateMHiggsPoleOneMomentumIteration = ""},
           If[FlexibleSUSY`FlexibleEFTHiggs === True,
              If[Head[susyScaleMatching] === List,
                 userMatching = Constraint`ApplyConstraints[susyScaleMatching];
                ];
              alphaS1Lmatching = Parameters`CreateLocalConstRefs[ThresholdCorrections`CalculateColorCoupling[scheme]] <> "\n" <>
                                 "delta_alpha_s += alpha_s/(2.*Pi)*(" <>
                                 CConversion`RValueToCFormString[ThresholdCorrections`CalculateColorCoupling[scheme]] <> ");\n";
              alphaEM1Lmatching = Parameters`CreateLocalConstRefs[ThresholdCorrections`CalculateElectromagneticCoupling[scheme]] <> "\n" <>
                                  "delta_alpha_em += alpha_em/(2.*Pi)*(" <>
                                  CConversion`RValueToCFormString[ThresholdCorrections`CalculateElectromagneticCoupling[scheme]] <> ");\n";
              higgsMassMatrix = Select[massMatrices, (TreeMasses`GetMassEigenstate[#] === SARAH`HiggsBoson)&];
              If[higgsMassMatrix === {},
                 Print["Error: Could not find mass matrix for ", SARAH`HiggsBoson];
                 Quit[1];
                ];
              setBSMParameters                  = FlexibleEFTHiggsMatching`SetBSMParameters[susyScaleMatching, GetMassMatrix[higgsMassMatrix[[1]]], "model."];
              setRunningUpQuarkMasses           = FlexibleEFTHiggsMatching`CalculateRunningUpQuarkMasses[];
              setRunningDownQuarkMasses         = FlexibleEFTHiggsMatching`CalculateRunningDownQuarkMasses[];
              setRunningDownLeptonMasses        = FlexibleEFTHiggsMatching`CalculateRunningDownLeptonMasses[];
              setYukawas                        = ThresholdCorrections`SetDRbarYukawaCouplings[];
              calculateMHiggsPoleOneMomentumIteration = FlexibleEFTHiggsMatching`CalculateMHiggsPoleOneMomentumIteration[SARAH`HiggsBoson];
              calculateMUpQuarkPole1L    = FlexibleEFTHiggsMatching`CalculateMUpQuarkPole1L[];
              calculateMDownQuarkPole1L  = FlexibleEFTHiggsMatching`CalculateMDownQuarkPole1L[];
              calculateMDownLeptonPole1L = FlexibleEFTHiggsMatching`CalculateMDownLeptonPole1L[];
             ];
           WriteOut`ReplaceInFiles[files,
                       { "@alphaS1Lmatching@"        -> IndentText[WrapLines[alphaS1Lmatching]],
                         "@alphaEM1Lmatching@"       -> IndentText[WrapLines[alphaEM1Lmatching]],
                         "@setBSMParameters@"        -> IndentText[setBSMParameters],
                         "@setRunningUpQuarkMasses@" -> IndentText[setRunningUpQuarkMasses],
                         "@setRunningDownQuarkMasses@" -> IndentText[setRunningDownQuarkMasses],
                         "@setRunningDownLeptonMasses@" -> IndentText[setRunningDownLeptonMasses],
                         "@calculateMUpQuarkPole1L@"    -> IndentText[calculateMUpQuarkPole1L],
                         "@calculateMDownQuarkPole1L@"  -> IndentText[calculateMDownQuarkPole1L],
                         "@calculateMDownLeptonPole1L@" -> IndentText[calculateMDownLeptonPole1L],
                         "@setYukawas@"              -> IndentText[WrapLines[setYukawas]],
                         "@applyUserMatching@"       -> IndentText[IndentText[WrapLines[userMatching]]],
                         "@calculateMHiggsPoleOneMomentumIteration@" -> IndentText[calculateMHiggsPoleOneMomentumIteration],
                         "@numberOfEWSBEquations@" -> ToString[TreeMasses`GetDimension[SARAH`HiggsBoson]],
                         Sequence @@ GeneralReplacementRules[]
                       } ];
        ];

WriteEWSBSolverClass[ewsbEquations_List, parametersFixedByEWSB_List, ewsbInitialGuessValues_List,
                     ewsbSubstitutions_List, ewsbSolution_List, freePhases_List, allowedEwsbSolvers_List,
                     files_List] :=
    Module[{numberOfIndependentEWSBEquations,
            ewsbEquationsTreeLevel, independentEwsbEquationsTreeLevel,
            independentEwsbEquations, higgsToEWSBEqAssociation,
            calculateOneLoopTadpolesNoStruct = "", calculateTwoLoopTadpolesNoStruct = "",
            ewsbInitialGuess = "", solveEwsbTreeLevel = "", setTreeLevelSolution = "", EWSBSolvers = "",
            setEWSBSolution = "", fillArrayWithEWSBParameters = "",
            solveEwsbWithTadpoles = "", getEWSBParametersFromVector = "",
            setEWSBParametersFromLocalCopies = "", applyEWSBSubstitutions = "",
            setModelParametersFromEWSB = ""},
           independentEwsbEquations = EWSB`GetLinearlyIndependentEqs[ewsbEquations, parametersFixedByEWSB,
                                                                     ewsbSubstitutions];
           numberOfIndependentEWSBEquations = Length[independentEwsbEquations];
           ewsbEquationsTreeLevel = ewsbEquations /. FlexibleSUSY`tadpole[_] -> 0;
           independentEwsbEquationsTreeLevel = independentEwsbEquations /. FlexibleSUSY`tadpole[_] -> 0;
           If[ewsbEquations =!= Table[0, {Length[ewsbEquations]}] &&
              Length[parametersFixedByEWSB] != numberOfIndependentEWSBEquations,
              Print["Error: There are ", numberOfIndependentEWSBEquations, " independent EWSB ",
                    "equations, but you want to fix ", Length[parametersFixedByEWSB],
                    " parameters: ", parametersFixedByEWSB];
             ];
           higgsToEWSBEqAssociation     = CreateHiggsToEWSBEqAssociation[];
           calculateOneLoopTadpolesNoStruct = SelfEnergies`FillArrayWithLoopTadpoles[1, higgsToEWSBEqAssociation, "tadpole", "+", "model."];
           If[SARAH`UseHiggs2LoopMSSM === True || FlexibleSUSY`UseHiggs2LoopNMSSM === True,
              calculateTwoLoopTadpolesNoStruct = SelfEnergies`FillArrayWithTwoLoopTadpoles[SARAH`HiggsBoson, "tadpole", "+", "model."];
             ];
           ewsbInitialGuess             = EWSB`FillInitialGuessArray[parametersFixedByEWSB, ewsbInitialGuessValues];
           solveEwsbTreeLevel           = EWSB`CreateTreeLevelEwsbSolver[ewsbSolution /. FlexibleSUSY`tadpole[_] -> 0];
           setTreeLevelSolution         = EWSB`SetTreeLevelSolution[ewsbSolution, ewsbSubstitutions];
           EWSBSolvers                  = EWSB`CreateEWSBRootFinders[allowedEwsbSolvers];
           setEWSBSolution              = EWSB`SetEWSBSolution[parametersFixedByEWSB, freePhases, "solution", "model."];
           If[ewsbSolution =!= {},
              fillArrayWithEWSBParameters  = EWSB`FillArrayWithParameters["ewsb_parameters", parametersFixedByEWSB];
             ];
           solveEwsbWithTadpoles        = EWSB`CreateEwsbSolverWithTadpoles[ewsbSolution];
           getEWSBParametersFromVector  = EWSB`GetEWSBParametersFromVector[parametersFixedByEWSB, freePhases, "ewsb_pars"];
           setEWSBParametersFromLocalCopies = EWSB`SetEWSBParametersFromLocalCopies[parametersFixedByEWSB, "model."];
           setModelParametersFromEWSB   = EWSB`SetModelParametersFromEWSB[parametersFixedByEWSB, ewsbSubstitutions, "model."];
           applyEWSBSubstitutions       = EWSB`ApplyEWSBSubstitutions[parametersFixedByEWSB, ewsbSubstitutions];
           WriteOut`ReplaceInFiles[files,
                          { "@calculateOneLoopTadpolesNoStruct@" -> IndentText[calculateOneLoopTadpolesNoStruct],
                            "@calculateTwoLoopTadpolesNoStruct@" -> IndentText[calculateTwoLoopTadpolesNoStruct],
                            "@numberOfEWSBEquations@"-> ToString[TreeMasses`GetDimension[SARAH`HiggsBoson]],
                            "@ewsbInitialGuess@"       -> IndentText[ewsbInitialGuess],
                            "@solveEwsbTreeLevel@"           -> IndentText[WrapLines[solveEwsbTreeLevel]],
                            "@setTreeLevelSolution@"         -> IndentText[WrapLines[setTreeLevelSolution]],
                            "@saveEWSBOutputParameters@"     -> IndentText[saveEWSBOutputParameters],
                            "@EWSBSolvers@"                  -> IndentText[IndentText[EWSBSolvers]],
                            "@fillArrayWithEWSBParameters@"  -> IndentText[fillArrayWithEWSBParameters],
                            "@solveEwsbWithTadpoles@"        -> IndentText[WrapLines[solveEwsbWithTadpoles]],
                            "@getEWSBParametersFromVector@"  -> IndentText[IndentText[getEWSBParametersFromVector]],
                            "@setEWSBParametersFromLocalCopies@" -> IndentText[IndentText[setEWSBParametersFromLocalCopies]],
                            "@setEWSBSolution@"              -> IndentText[setEWSBSolution],
                            "@applyEWSBSubstitutions@"       -> IndentText[IndentText[WrapLines[applyEWSBSubstitutions]]],
                            "@setModelParametersFromEWSB@"   -> IndentText[WrapLines[setModelParametersFromEWSB]],
                            Sequence @@ GeneralReplacementRules[]
                          } ];
          ];

WriteSemiAnalyticEWSBSolverClass[ewsbEquations_List, parametersFixedByEWSB_List, ewsbInitialGuessValues_List,
                                 ewsbSubstitutions_List, ewsbSolution_List, freePhases_List, allowedEwsbSolvers_List,
                                 solutions_List, files_List] :=
    Module[{semiAnalyticSubs, additionalEwsbSubs, numberOfIndependentEWSBEquations,
            ewsbEquationsTreeLevel,
            independentEwsbEquations, higgsToEWSBEqAssociation,
            calculateOneLoopTadpolesNoStruct = "", calculateTwoLoopTadpolesNoStruct = "",
            ewsbInitialGuess = "", solveEwsbTreeLevel = "", setTreeLevelSolution = "", EWSBSolvers = "",
            setEWSBSolution = "", fillArrayWithEWSBParameters = "",
            solveEwsbWithTadpoles = "", getEWSBParametersFromVector = "",
            setEWSBParametersFromLocalCopies = "", applyEWSBSubstitutions = "",
            setModelParametersFromEWSB = "", setBoundaryValueParametersFromLocalCopies = ""},
           semiAnalyticSubs = SemiAnalytic`GetSemiAnalyticEWSBSubstitutions[solutions];
           additionalEwsbSubs = Complement[ewsbSubstitutions, semiAnalyticSubs];
           independentEwsbEquations = EWSB`GetLinearlyIndependentEqs[ewsbEquations, parametersFixedByEWSB, ewsbSubstitutions];
           numberOfIndependentEWSBEquations = Length[independentEwsbEquations];
           ewsbEquationsTreeLevel = ewsbEquations /. FlexibleSUSY`tadpole[_] -> 0;
           If[ewsbEquations =!= Table[0, {Length[ewsbEquations]}] &&
              Length[parametersFixedByEWSB] != numberOfIndependentEWSBEquations,
              Print["Error: There are ", numberOfIndependentEWSBEquations, " independent EWSB ",
                    "equations, but you want to fix ", Length[parametersFixedByEWSB],
                    " parameters: ", parametersFixedByEWSB];
             ];
           higgsToEWSBEqAssociation     = CreateHiggsToEWSBEqAssociation[];
           calculateOneLoopTadpolesNoStruct = SelfEnergies`FillArrayWithLoopTadpoles[1, higgsToEWSBEqAssociation, "tadpole", "+", "model."];
           If[SARAH`UseHiggs2LoopMSSM === True || FlexibleSUSY`UseHiggs2LoopNMSSM === True,
              calculateTwoLoopTadpolesNoStruct = SelfEnergies`FillArrayWithTwoLoopTadpoles[SARAH`HiggsBoson, "tadpole", "+", "model."];
             ];
           ewsbInitialGuess             = EWSB`FillInitialGuessArray[parametersFixedByEWSB, ewsbInitialGuessValues];
           solveEwsbTreeLevel = EWSB`CreateTreeLevelEwsbSolver[ewsbSolution /. FlexibleSUSY`tadpole[_] -> 0];
           solveEwsbTreeLevel = SemiAnalytic`ReplacePreprocessorMacros[solveEwsbTreeLevel, solutions];
           setTreeLevelSolution = SemiAnalytic`SetTreeLevelEWSBSolution[ewsbSolution, solutions, additionalEwsbSubs];
           solveEwsbWithTadpoles        = EWSB`CreateEwsbSolverWithTadpoles[ewsbSolution];
           solveEwsbWithTadpoles        = SemiAnalytic`ReplacePreprocessorMacros[solveEwsbWithTadpoles, solutions];
           EWSBSolvers                  = EWSB`CreateEWSBRootFinders[allowedEwsbSolvers];
           setEWSBSolution              = EWSB`SetEWSBSolution[parametersFixedByEWSB, freePhases, "solution", "model."];
           If[ewsbSolution =!= {},
              fillArrayWithEWSBParameters  = EWSB`FillArrayWithParameters["ewsb_parameters", parametersFixedByEWSB];
             ];
           getEWSBParametersFromVector  = EWSB`GetEWSBParametersFromVector[parametersFixedByEWSB, freePhases, "ewsb_pars"];
           setEWSBParametersFromLocalCopies = EWSB`SetEWSBParametersFromLocalCopies[parametersFixedByEWSB, "model."];
           setModelParametersFromEWSB   = EWSB`SetModelParametersFromEWSB[parametersFixedByEWSB, additionalEwsbSubs, "model."];
           applyEWSBSubstitutions       = EWSB`ApplyEWSBSubstitutions[parametersFixedByEWSB, additionalEwsbSubs];
           setBoundaryValueParametersFromLocalCopies = SemiAnalytic`SetBoundaryValueParametersFromLocalCopies[parametersFixedByEWSB, solutions];
           WriteOut`ReplaceInFiles[files,
                          { "@calculateOneLoopTadpolesNoStruct@" -> IndentText[calculateOneLoopTadpolesNoStruct],
                            "@calculateTwoLoopTadpolesNoStruct@" -> IndentText[calculateTwoLoopTadpolesNoStruct],
                            "@numberOfEWSBEquations@"-> ToString[TreeMasses`GetDimension[SARAH`HiggsBoson]],
                            "@ewsbInitialGuess@"       -> IndentText[ewsbInitialGuess],
                            "@solveEwsbTreeLevel@"           -> IndentText[WrapLines[solveEwsbTreeLevel]],
                            "@setTreeLevelSolution@"         -> IndentText[WrapLines[setTreeLevelSolution]],
                            "@saveEWSBOutputParameters@"     -> IndentText[saveEWSBOutputParameters],
                            "@EWSBSolvers@"                  -> IndentText[IndentText[EWSBSolvers]],
                            "@fillArrayWithEWSBParameters@"  -> IndentText[fillArrayWithEWSBParameters],
                            "@solveEwsbWithTadpoles@"        -> IndentText[WrapLines[solveEwsbWithTadpoles]],
                            "@getEWSBParametersFromVector@"  -> IndentText[IndentText[getEWSBParametersFromVector]],
                            "@setEWSBParametersFromLocalCopies@" -> IndentText[IndentText[setEWSBParametersFromLocalCopies]],
                            "@setEWSBSolution@"              -> IndentText[setEWSBSolution],
                            "@applyEWSBSubstitutions@"       -> IndentText[IndentText[WrapLines[applyEWSBSubstitutions]]],
                            "@setModelParametersFromEWSB@"   -> IndentText[WrapLines[setModelParametersFromEWSB]],
                            "@setBoundaryValueParametersFromLocalCopies@" -> IndentText[IndentText[WrapLines[setBoundaryValueParametersFromLocalCopies]]],
                            "@setBoundaryValueParametersFromSolution@" -> IndentText[WrapLines[setBoundaryValueParametersFromLocalCopies]],
                            Sequence @@ GeneralReplacementRules[]
                          } ];
          ];

WriteModelClass[massMatrices_List, ewsbEquations_List,
                parametersFixedByEWSB_List, ewsbSubstitutions_List,
                nPointFunctions_List, vertexRules_List, phases_List,
                files_List, diagonalizationPrecision_List] :=
    Module[{ewsbEquationsTreeLevel, independentEwsbEquationsTreeLevel,
            independentEwsbEquations,
            massGetters = "", k,
            mixingMatrixGetters = "",
            slhaPoleMassGetters = "", slhaPoleMixingMatrixGetters = "",
            higgsMassGetters = "", higgsToEWSBEqAssociation,
            tadpoleEqPrototypes = "", tadpoleEqFunctions = "",
            numberOfEWSBEquations = Length[ewsbEquations],
            calculateTreeLevelTadpoles = "", divideTadpoleByVEV = "",
            calculateOneLoopTadpoles = "", calculateTwoLoopTadpoles = "",
            physicalMassesDef = "", mixingMatricesDef = "",
            massCalculationPrototypes = "", massCalculationFunctions = "",
            calculateAllMasses = "",
            selfEnergyPrototypes = "", selfEnergyFunctions = "",
            twoLoopTadpolePrototypes = "", twoLoopTadpoleFunctions = "",
            twoLoopSelfEnergyPrototypes = "", twoLoopSelfEnergyFunctions = "",
            threeLoopSelfEnergyPrototypes = "", threeLoopSelfEnergyFunctions = "",
            thirdGenerationHelperPrototypes = "", thirdGenerationHelperFunctions = "",
            phasesDefinition = "", phasesGetterSetters = "",
            extraParameterDefs = "",
            extraParameterSetters = "", extraParameterGetters = "",
            loopMassesPrototypes = "", loopMassesFunctions = "",
            runningDRbarMassesPrototypes = "", runningDRbarMassesFunctions = "",
            callAllLoopMassFunctions = "",
            callAllLoopMassFunctionsInThreads = "",
            printMasses = "", printMixingMatrices = "",
            getMixings = "", setMixings = "",
            getMasses = "", setMasses = "",
            masses, mixingMatrices,
            dependencePrototypes, dependenceFunctions,
            clearOutputParameters = "",
            clearPhases = "", clearExtraParameters = "",
            softScalarMasses, treeLevelEWSBOutputParameters,
            saveEWSBOutputParameters,
            solveTreeLevelEWSBviaSoftHiggsMasses,
            solveEWSBTemporarily,
            copyDRbarMassesToPoleMasses = "",
            reorderDRbarMasses = "", reorderPoleMasses = "",
            checkPoleMassesForTachyons = "",
            twoLoopHiggsHeaders = "", threeLoopHiggsHeaders = "",
            twoLoopThresholdHeaders = "",
            lspGetters = "", lspFunctions = "",
            convertMixingsToSLHAConvention = "",
            convertMixingsToHKConvention = "",
            enablePoleMassThreads = True
           },
           convertMixingsToSLHAConvention = WriteOut`ConvertMixingsToSLHAConvention[massMatrices];
           convertMixingsToHKConvention   = WriteOut`ConvertMixingsToHKConvention[massMatrices];
           independentEwsbEquations = EWSB`GetLinearlyIndependentEqs[ewsbEquations, parametersFixedByEWSB,
                                                                     ewsbSubstitutions];
           ewsbEquationsTreeLevel = ewsbEquations /. FlexibleSUSY`tadpole[_] -> 0;
           independentEwsbEquationsTreeLevel = independentEwsbEquations /. FlexibleSUSY`tadpole[_] -> 0;
           For[k = 1, k <= Length[massMatrices], k++,
               massGetters          = massGetters <> TreeMasses`CreateMassGetter[massMatrices[[k]]];
               mixingMatrixGetters  = mixingMatrixGetters <> TreeMasses`CreateMixingMatrixGetter[massMatrices[[k]]];
               physicalMassesDef    = physicalMassesDef <> TreeMasses`CreatePhysicalMassDefinition[massMatrices[[k]]];
               mixingMatricesDef    = mixingMatricesDef <> TreeMasses`CreateMixingMatrixDefinition[massMatrices[[k]]];
               clearOutputParameters = clearOutputParameters <> TreeMasses`ClearOutputParameters[massMatrices[[k]]];
               copyDRbarMassesToPoleMasses = copyDRbarMassesToPoleMasses <> TreeMasses`CopyDRBarMassesToPoleMasses[massMatrices[[k]]];
               massCalculationPrototypes = massCalculationPrototypes <> TreeMasses`CreateMassCalculationPrototype[massMatrices[[k]]];
               massCalculationFunctions  = massCalculationFunctions  <> TreeMasses`CreateMassCalculationFunction[massMatrices[[k]]];
              ];
           higgsMassGetters =
               Utils`StringZipWithSeparator[
                   TreeMasses`CreateHiggsMassGetters[SARAH`HiggsBoson,""],
                   TreeMasses`CreateHiggsMassGetters[SARAH`ChargedHiggs,""],
                   TreeMasses`CreateHiggsMassGetters[SARAH`PseudoScalar,""],
                   "\n"
               ];
           clearPhases = Phases`ClearPhases[phases];
           calculateAllMasses = TreeMasses`CallMassCalculationFunctions[massMatrices];
           tadpoleEqPrototypes = EWSB`CreateEWSBEqPrototype[SARAH`HiggsBoson];
           tadpoleEqFunctions  = EWSB`CreateEWSBEqFunction[SARAH`HiggsBoson, ewsbEquationsTreeLevel];
           higgsToEWSBEqAssociation     = CreateHiggsToEWSBEqAssociation[];
           calculateTreeLevelTadpoles   = EWSB`FillArrayWithEWSBEqs[SARAH`HiggsBoson, "tadpole"];
           calculateOneLoopTadpoles     = SelfEnergies`FillArrayWithLoopTadpoles[1, higgsToEWSBEqAssociation, "tadpole", "-"];
           divideTadpoleByVEV           = SelfEnergies`DivideTadpoleByVEV[Parameters`DecreaseIndexLiterals @ CreateVEVToTadpoleAssociation[], "tadpole"];
           If[SARAH`UseHiggs2LoopMSSM === True || FlexibleSUSY`UseHiggs2LoopNMSSM === True,
              calculateTwoLoopTadpoles  = SelfEnergies`FillArrayWithTwoLoopTadpoles[SARAH`HiggsBoson, "tadpole", "-"];
             ];
           If[FlexibleSUSY`UseHiggs2LoopSM === True,
              {twoLoopSelfEnergyPrototypes, twoLoopSelfEnergyFunctions} = SelfEnergies`CreateTwoLoopSelfEnergiesSM[{SARAH`HiggsBoson}];
              twoLoopHiggsHeaders = "#include \"sm_twoloophiggs.hpp\"\n";
             ];
           If[FlexibleSUSY`UseHiggs3LoopSplit === True,
              {threeLoopSelfEnergyPrototypes, threeLoopSelfEnergyFunctions} = SelfEnergies`CreateThreeLoopSelfEnergiesSplit[{SARAH`HiggsBoson}];
              threeLoopHiggsHeaders = "#include \"split_threeloophiggs.hpp\"\n";
             ];
           If[SARAH`UseHiggs2LoopMSSM === True,
              {twoLoopTadpolePrototypes, twoLoopTadpoleFunctions} = SelfEnergies`CreateTwoLoopTadpolesMSSM[SARAH`HiggsBoson];
              {twoLoopSelfEnergyPrototypes, twoLoopSelfEnergyFunctions} = SelfEnergies`CreateTwoLoopSelfEnergiesMSSM[{SARAH`HiggsBoson, SARAH`PseudoScalar}];
              twoLoopHiggsHeaders = "#include \"sfermions.hpp\"\n#include \"mssm_twoloophiggs.hpp\"\n";
             ];
           If[FlexibleSUSY`UseHiggs2LoopNMSSM === True,
              {twoLoopTadpolePrototypes, twoLoopTadpoleFunctions} = SelfEnergies`CreateTwoLoopTadpolesNMSSM[SARAH`HiggsBoson];
              {twoLoopSelfEnergyPrototypes, twoLoopSelfEnergyFunctions} = SelfEnergies`CreateTwoLoopSelfEnergiesNMSSM[{SARAH`HiggsBoson, SARAH`PseudoScalar}];
              twoLoopHiggsHeaders = "#include \"sfermions.hpp\"\n#include \"mssm_twoloophiggs.hpp\"\n#include \"nmssm_twoloophiggs.hpp\"\n";
             ];
           If[FlexibleSUSY`UseMSSMYukawa2LoopSQCD === True,
              twoLoopThresholdHeaders = "#include \"mssm_twoloop_mb.hpp\"\n#include \"mssm_twoloop_mt.hpp\"";
             ];
           If[SARAH`UseHiggs2LoopMSSM === True ||
              FlexibleSUSY`UseHiggs2LoopNMSSM === True ||
              FlexibleSUSY`UseMSSMYukawa2LoopSQCD === True,
              {thirdGenerationHelperPrototypes, thirdGenerationHelperFunctions} = TreeMasses`CreateThirdGenerationHelpers[];
             ];
           {selfEnergyPrototypes, selfEnergyFunctions} = SelfEnergies`CreateNPointFunctions[nPointFunctions, vertexRules];
           phasesDefinition             = Phases`CreatePhasesDefinition[phases];
           phasesGetterSetters          = Phases`CreatePhasesGetterSetters[phases];
           If[Parameters`GetExtraParameters[] =!= {},
              extraParameterDefs           = StringJoin[Parameters`CreateParameterDefinitionAndDefaultInitialize
                                                        /@ Parameters`GetExtraParameters[]];
              extraParameterGetters        = StringJoin[CConversion`CreateInlineGetters[CConversion`ToValidCSymbolString[#],
                                                                                        Parameters`GetType[#]]& /@
                                                        Parameters`GetExtraParameters[]];
              extraParameterSetters        = StringJoin[CConversion`CreateInlineSetters[CConversion`ToValidCSymbolString[#],
                                                                                        Parameters`GetType[#]]& /@
                                                        Parameters`GetExtraParameters[]];
              clearExtraParameters         = StringJoin[CConversion`SetToDefault[CConversion`ToValidCSymbolString[#],
                                                                                 Parameters`GetType[#]]& /@
                                                        Parameters`GetExtraParameters[]];
             ];
           loopMassesPrototypes         = LoopMasses`CreateOneLoopPoleMassPrototypes[];
           (* If you want to add tadpoles, call the following routine like this:
              CreateOneLoopPoleMassFunctions[diagonalizationPrecision, Cases[nPointFunctions, SelfEnergies`Tadpole[___]], vevs];
              *)
           loopMassesFunctions          = LoopMasses`CreateOneLoopPoleMassFunctions[diagonalizationPrecision, {}, {}];
           runningDRbarMassesPrototypes = LoopMasses`CreateRunningDRbarMassPrototypes[];
           runningDRbarMassesFunctions  = LoopMasses`CreateRunningDRbarMassFunctions[FlexibleSUSY`FSRenormalizationScheme];
           enablePoleMassThreads = False;
           callAllLoopMassFunctions     = LoopMasses`CallAllPoleMassFunctions[FlexibleSUSY`FSEigenstates, enablePoleMassThreads];
           enablePoleMassThreads = True;
           callAllLoopMassFunctionsInThreads = LoopMasses`CallAllPoleMassFunctions[FlexibleSUSY`FSEigenstates, enablePoleMassThreads];
           masses                       = Flatten[(FlexibleSUSY`M[TreeMasses`GetMassEigenstate[#]]& /@ massMatrices) /.
                                                  FlexibleSUSY`M[p_List] :> (FlexibleSUSY`M /@ p)];
           {lspGetters, lspFunctions}   = LoopMasses`CreateLSPFunctions[FlexibleSUSY`PotentialLSPParticles];
           printMasses                  = WriteOut`PrintParameters[masses, "ostr"];
           getMixings                   = TreeMasses`CreateMixingArrayGetter[massMatrices];
           setMixings                   = TreeMasses`CreateMixingArraySetter[massMatrices, "pars"];
           getMasses                    = TreeMasses`CreateMassArrayGetter[massMatrices];
           setMasses                    = TreeMasses`CreateMassArraySetter[massMatrices, "pars"];
           mixingMatrices               = Flatten[TreeMasses`GetMixingMatrixSymbol[#]& /@ massMatrices];
           printMixingMatrices          = WriteOut`PrintParameters[mixingMatrices, "ostr"];
           dependencePrototypes      = TreeMasses`CreateDependencePrototypes[massMatrices];
           dependenceFunctions       = TreeMasses`CreateDependenceFunctions[massMatrices];
           If[Head[SARAH`ListSoftBreakingScalarMasses] === List,
              softScalarMasses          = DeleteDuplicates[SARAH`ListSoftBreakingScalarMasses];,
              softScalarMasses          = {};
             ];
           (* find soft Higgs masses that appear in tree-level EWSB eqs. *)
           If[Head[FlexibleSUSY`FSSolveEWSBTreeLevelFor] =!= List ||
              FlexibleSUSY`FSSolveEWSBTreeLevelFor === {},
              treeLevelEWSBOutputParameters = Select[softScalarMasses, (!FreeQ[ewsbEquations, #])&];
              ,
              treeLevelEWSBOutputParameters = FlexibleSUSY`FSSolveEWSBTreeLevelFor;
             ];
           treeLevelEWSBOutputParameters = Parameters`DecreaseIndexLiterals[Parameters`ExpandExpressions[Parameters`AppendGenerationIndices[treeLevelEWSBOutputParameters]]];
           If[Head[treeLevelEWSBOutputParameters] === List && Length[treeLevelEWSBOutputParameters] > 0,
              saveEWSBOutputParameters = Parameters`SaveParameterLocally[treeLevelEWSBOutputParameters];
              solveTreeLevelEWSBviaSoftHiggsMasses = EWSB`FindSolutionAndFreePhases[independentEwsbEquationsTreeLevel,
                                                                                    treeLevelEWSBOutputParameters][[1]];
              If[solveTreeLevelEWSBviaSoftHiggsMasses === {},
                 Print["Error: could not find an analytic solution to the tree-level EWSB eqs."];
                 Print["   for the parameters ", treeLevelEWSBOutputParameters];
                 Quit[1];
                ];
              solveTreeLevelEWSBviaSoftHiggsMasses = EWSB`CreateMemberTreeLevelEwsbSolver[solveTreeLevelEWSBviaSoftHiggsMasses];
              solveEWSBTemporarily = IndentText["solve_ewsb_tree_level_custom();"];
              ,
              saveEWSBOutputParameters = Parameters`SaveParameterLocally[parametersFixedByEWSB];
              solveTreeLevelEWSBviaSoftHiggsMasses = "";
              solveEWSBTemporarily = EWSB`SolveEWSBIgnoringFailures[0];
             ];
           reorderDRbarMasses           = TreeMasses`ReorderGoldstoneBosons[""];
           reorderPoleMasses            = TreeMasses`ReorderGoldstoneBosons["PHYSICAL"];
           checkPoleMassesForTachyons   = TreeMasses`CheckPoleMassesForTachyons["PHYSICAL"];
           WriteOut`ReplaceInFiles[files,
                          { "@lspGetters@"           -> IndentText[lspGetters],
                            "@lspFunctions@"         -> lspFunctions,
                            "@massGetters@"          -> IndentText[massGetters],
                            "@mixingMatrixGetters@"  -> IndentText[mixingMatrixGetters],
                            "@slhaPoleMassGetters@"  -> IndentText[slhaPoleMassGetters],
                            "@slhaPoleMixingMatrixGetters@" -> IndentText[slhaPoleMixingMatrixGetters],
                            "@higgsMassGetterPrototypes@"   -> IndentText[higgsMassGetters[[1]]],
                            "@higgsMassGetters@"     -> higgsMassGetters[[2]],
                            "@tadpoleEqPrototypes@"  -> IndentText[tadpoleEqPrototypes],
                            "@tadpoleEqFunctions@"   -> tadpoleEqFunctions,
                            "@numberOfEWSBEquations@"-> ToString[TreeMasses`GetDimension[SARAH`HiggsBoson]],
                            "@calculateTreeLevelTadpoles@" -> IndentText[calculateTreeLevelTadpoles],
                            "@calculateOneLoopTadpoles@"   -> IndentText @ IndentText[calculateOneLoopTadpoles],
                            "@calculateTwoLoopTadpoles@"   -> IndentText @ IndentText @ IndentText[calculateTwoLoopTadpoles],
                            "@divideTadpoleByVEV@"     -> IndentText[divideTadpoleByVEV],
                            "@clearOutputParameters@"  -> IndentText[clearOutputParameters],
                            "@clearPhases@"            -> IndentText[clearPhases],
                            "@copyDRbarMassesToPoleMasses@" -> IndentText[copyDRbarMassesToPoleMasses],
                            "@reorderDRbarMasses@"     -> IndentText[reorderDRbarMasses],
                            "@reorderPoleMasses@"      -> IndentText[reorderPoleMasses],
                            "@checkPoleMassesForTachyons@" -> IndentText[checkPoleMassesForTachyons],
                            "@physicalMassesDef@"      -> IndentText[physicalMassesDef],
                            "@mixingMatricesDef@"      -> IndentText[mixingMatricesDef],
                            "@massCalculationPrototypes@" -> IndentText[massCalculationPrototypes],
                            "@massCalculationFunctions@"  -> WrapLines[massCalculationFunctions],
                            "@calculateAllMasses@"        -> IndentText[calculateAllMasses],
                            "@selfEnergyPrototypes@"      -> IndentText[selfEnergyPrototypes],
                            "@selfEnergyFunctions@"       -> selfEnergyFunctions,
                            "@twoLoopTadpolePrototypes@"  -> IndentText[twoLoopTadpolePrototypes],
                            "@twoLoopTadpoleFunctions@"   -> twoLoopTadpoleFunctions,
                            "@twoLoopSelfEnergyPrototypes@" -> IndentText[twoLoopSelfEnergyPrototypes],
                            "@twoLoopSelfEnergyFunctions@"  -> twoLoopSelfEnergyFunctions,
                            "@twoLoopHiggsHeaders@"       -> twoLoopHiggsHeaders,
                            "@twoLoopThresholdHeaders@"   -> twoLoopThresholdHeaders,
                            "@threeLoopSelfEnergyPrototypes@" -> IndentText[threeLoopSelfEnergyPrototypes],
                            "@threeLoopSelfEnergyFunctions@"  -> threeLoopSelfEnergyFunctions,
                            "@threeLoopHiggsHeaders@"         -> threeLoopHiggsHeaders,
                            "@thirdGenerationHelperPrototypes@" -> IndentText[thirdGenerationHelperPrototypes],
                            "@thirdGenerationHelperFunctions@"  -> thirdGenerationHelperFunctions,
                            "@phasesDefinition@"          -> IndentText[phasesDefinition],
                            "@phasesGetterSetters@"          -> IndentText[phasesGetterSetters],
                            "@extraParameterDefs@"           -> IndentText[extraParameterDefs],
                            "@extraParameterGetters@"        -> IndentText[extraParameterGetters],
                            "@extraParameterSetters@"        -> IndentText[extraParameterSetters],
                            "@clearExtraParameters@"         -> IndentText[clearExtraParameters],
                            "@loopMassesPrototypes@"         -> IndentText[WrapLines[loopMassesPrototypes]],
                            "@loopMassesFunctions@"          -> WrapLines[loopMassesFunctions],
                            "@runningDRbarMassesPrototypes@" -> IndentText[runningDRbarMassesPrototypes],
                            "@runningDRbarMassesFunctions@"  -> WrapLines[runningDRbarMassesFunctions],
                            "@callAllLoopMassFunctions@"     -> IndentText[callAllLoopMassFunctions],
                            "@callAllLoopMassFunctionsInThreads@" -> IndentText[callAllLoopMassFunctionsInThreads],
                            "@printMasses@"                  -> IndentText[printMasses],
                            "@getMixings@"                   -> IndentText[getMixings],
                            "@setMixings@"                   -> IndentText[setMixings],
                            "@getMasses@"                    -> IndentText[getMasses],
                            "@setMasses@"                    -> IndentText[setMasses],
                            "@printMixingMatrices@"          -> IndentText[printMixingMatrices],
                            "@dependencePrototypes@"         -> IndentText[dependencePrototypes],
                            "@dependenceFunctions@"          -> WrapLines[dependenceFunctions],
                            "@saveEWSBOutputParameters@"     -> IndentText[saveEWSBOutputParameters],
                            "@solveTreeLevelEWSBviaSoftHiggsMasses@" -> IndentText[WrapLines[solveTreeLevelEWSBviaSoftHiggsMasses]],
                            "@solveEWSBTemporarily@"         -> solveEWSBTemporarily,
                            "@convertMixingsToSLHAConvention@" -> IndentText[convertMixingsToSLHAConvention],
                            "@convertMixingsToHKConvention@"   -> IndentText[convertMixingsToHKConvention],
                            Sequence @@ GeneralReplacementRules[]
                          } ];
          ];

WriteBVPSolverTemplates[files_List] :=
    WriteOut`ReplaceInFiles[files, { Sequence @@ GeneralReplacementRules[] }];

WriteSolverMatchingClass[files_List] :=
    WriteOut`ReplaceInFiles[files, { Sequence @@ GeneralReplacementRules[] }];

WriteTwoScaleModelClass[files_List] :=
    WriteOut`ReplaceInFiles[files, { Sequence @@ GeneralReplacementRules[] }];

WriteSemiAnalyticSolutionsClass[semiAnalyticBCs_List, semiAnalyticSolns_List, files_List] :=
    Module[{semiAnalyticSolutionsDefs = "", boundaryValueStructDefs = "", boundaryValuesDefs = "",
            boundaryValueGetters = "", boundaryValueSetters = "", coefficientGetters = "",
            createBasisEvaluators = "", applyBoundaryConditions = "",
            datasets, numberOfTrialPoints, initializeTrialBoundaryValues = "",
            createLinearSystemSolvers = "", calculateCoefficients = "",
            evaluateSemiAnalyticSolns = "",
            calculateCoefficientsPrototypes = "", calculateCoefficientsFunctions = ""},
           semiAnalyticSolutionsDefs = SemiAnalytic`CreateSemiAnalyticSolutionsDefinitions[semiAnalyticSolns];
           boundaryValueStructDefs = SemiAnalytic`CreateLocalBoundaryValuesDefinitions[semiAnalyticSolns];
           boundaryValuesDefs = SemiAnalytic`CreateBoundaryValuesDefinitions[semiAnalyticSolns];
           coefficientGetters = SemiAnalytic`CreateSemiAnalyticCoefficientGetters[semiAnalyticSolns];
           boundaryValueGetters = SemiAnalytic`CreateBoundaryValueGetters[semiAnalyticSolns];
           boundaryValueSetters = SemiAnalytic`CreateBoundaryValueSetters[semiAnalyticSolns];
           createBasisEvaluators = SemiAnalytic`CreateBasisEvaluators[semiAnalyticSolns];
           datasets = SemiAnalytic`ConstructTrialDatasets[semiAnalyticSolns];
           createLinearSystemSolvers = SemiAnalytic`CreateLinearSystemSolvers[datasets, semiAnalyticSolns];
           {numberOfTrialPoints, initializeTrialBoundaryValues} = SemiAnalytic`InitializeTrialInputValues[datasets];
           applyBoundaryConditions = SemiAnalytic`ApplySemiAnalyticBoundaryConditions[semiAnalyticBCs, semiAnalyticSolns];
           evaluateSemiAnalyticSolns = SemiAnalytic`EvaluateSemiAnalyticSolutions[semiAnalyticSolns];
           calculateCoefficients = SemiAnalytic`CalculateCoefficients[datasets];
           {calculateCoefficientsPrototypes, calculateCoefficientsFunctions} = SemiAnalytic`CreateCoefficientsCalculations[semiAnalyticSolns];
           WriteOut`ReplaceInFiles[files, { "@semiAnalyticSolutionsDefs@" -> IndentText[WrapLines[semiAnalyticSolutionsDefs]],
                                            "@boundaryValuesDefs@" -> IndentText[WrapLines[boundaryValuesDefs]],
                                            "@boundaryValueStructDefs@" -> IndentText[IndentText[WrapLines[boundaryValueStructDefs]]],
                                            "@boundaryValueGetters@" -> IndentText[WrapLines[boundaryValueGetters]],
                                            "@boundaryValueSetters@" -> IndentText[WrapLines[boundaryValueSetters]],
                                            "@coefficientGetters@" -> IndentText[WrapLines[coefficientGetters]],
                                            "@numberOfTrialPoints@" -> ToString[numberOfTrialPoints],
                                            "@initializeTrialBoundaryValues@" -> IndentText[WrapLines[initializeTrialBoundaryValues]],
                                            "@createBasisEvaluators@" -> IndentText[WrapLines[createBasisEvaluators]],
                                            "@createLinearSystemSolvers@" -> IndentText[WrapLines[createLinearSystemSolvers]],
                                            "@calculateCoefficients@" -> IndentText[calculateCoefficients],
                                            "@applyBoundaryConditions@" -> IndentText[WrapLines[applyBoundaryConditions]],
                                            "@evaluateSemiAnalyticSolns@" -> IndentText[WrapLines[evaluateSemiAnalyticSolns]],
                                            "@calculateCoefficientsPrototypes@" -> IndentText[calculateCoefficientsPrototypes],
                                            "@calculateCoefficientsFunctions@" -> calculateCoefficientsFunctions,
                                            Sequence @@ GeneralReplacementRules[] }];
          ];

WriteSemiAnalyticModelClass[semiAnalyticBCs_List, semiAnalyticSolns_List, files_List] :=
    Module[{getBoundaryValueParameters = "", setBoundaryValueParameters = "",
            getSemiAnalyticCoefficients = "", printSemiAnalyticCoefficients = ""},
           getBoundaryValueParameters = SemiAnalytic`GetModelBoundaryValueParameters[semiAnalyticSolns];
           setBoundaryValueParameters = SemiAnalytic`SetModelBoundaryValueParameters[semiAnalyticSolns];
           getSemiAnalyticCoefficients = SemiAnalytic`GetModelCoefficients[semiAnalyticSolns];
           printSemiAnalyticCoefficients = SemiAnalytic`PrintModelCoefficients[semiAnalyticSolns, "out"];
           WriteOut`ReplaceInFiles[files, { "@getBoundaryValueParameters@"   -> IndentText[WrapLines[getBoundaryValueParameters]],
                                            "@setBoundaryValueParameters@"   -> IndentText[WrapLines[setBoundaryValueParameters]],
                                            "@getSemiAnalyticCoefficients@"  -> IndentText[WrapLines[getSemiAnalyticCoefficients]],
                                            "@printSemiAnalyticCoefficients@" -> IndentText[WrapLines[printSemiAnalyticCoefficients]],
                                            Sequence @@ GeneralReplacementRules[] }];
          ];

WriteTwoScaleSpectrumGeneratorClass[files_List] :=
    Module[{fillSMFermionPoleMasses = ""},
           fillSMFermionPoleMasses = FlexibleEFTHiggsMatching`FillSMFermionPoleMasses[];
           WriteOut`ReplaceInFiles[files,
                          { "@fillSMFermionPoleMasses@" -> IndentText[fillSMFermionPoleMasses],
                            Sequence @@ GeneralReplacementRules[]
                          } ];
          ];

WriteSemiAnalyticSpectrumGeneratorClass[files_List] :=
    Module[{setSemiAnalyticConstraint = ".set_soft_parameters_constraint(&soft_constraint);\n",
            fillSMFermionPoleMasses = ""},
           fillSMFermionPoleMasses = FlexibleEFTHiggsMatching`FillSMFermionPoleMasses[];
           Which[SemiAnalytic`IsSemiAnalyticConstraint[FlexibleSUSY`HighScaleInput],
                 setSemiAnalyticConstraint = "high_scale_constraint" <> setSemiAnalyticConstraint,
                 SemiAnalytic`IsSemiAnalyticConstraint[FlexibleSUSY`SUSYScaleInput],
                 setSemiAnalyticConstraint = "susy_scale_constraint" <> setSemiAnalyticConstraint,
                 SemiAnalytic`IsSemiAnalyticConstraint[FlexibleSUSY`LowScaleInput],
                 setSemiAnalyticConstraint = "low_scale_constraint" <> setSemiAnalyticConstraint,
                 True,
                 setSemiAnalyticConstraint = "high_scale_constraint" <> setSemiAnalyticConstraint
                ];
           WriteOut`ReplaceInFiles[files,
                          { "@setSemiAnalyticConstraint@" -> IndentText[WrapLines[setSemiAnalyticConstraint]],
                            "@fillSMFermionPoleMasses@" -> IndentText[fillSMFermionPoleMasses],
                            Sequence @@ GeneralReplacementRules[]
                          } ];
          ];

WriteEffectiveCouplings[couplings_List, settings_List, massMatrices_List, vertexRules_List, files_List] :=
    Module[{i, partialWidthGetterPrototypes, partialWidthGetters,
            loopCouplingsGetters, loopCouplingsDefs, mixingMatricesDefs = "",
            loopCouplingsInit, mixingMatricesInit = "", copyMixingMatrices = "",
            setSMStrongCoupling = "",
            calculateScalarScalarLoopQCDFactor, calculateScalarFermionLoopQCDFactor,
            calculatePseudocalarFermionLoopQCDFactor,
            calculateScalarQCDScalingFactor, calculatePseudoscalarQCDScalingFactor,
            calculateLoopCouplings, loopCouplingsPrototypes,
            loopCouplingsFunctions},
           {partialWidthGetterPrototypes, partialWidthGetters} = EffectiveCouplings`CalculatePartialWidths[couplings];
           If[ValueQ[SARAH`strongCoupling],
              setSMStrongCoupling = "model.set_" <> CConversion`ToValidCSymbolString[SARAH`strongCoupling] <> "(sm.get_g3());\n";
             ];
           loopCouplingsGetters = EffectiveCouplings`CreateEffectiveCouplingsGetters[couplings];
           For[i = 1, i <= Length[massMatrices], i++,
               mixingMatricesDefs = mixingMatricesDefs <> TreeMasses`CreateMixingMatrixDefinition[massMatrices[[i]]];
               mixingMatricesInit = mixingMatricesInit <> EffectiveCouplings`InitializeMixingFromModelInput[massMatrices[[i]]];
               copyMixingMatrices = copyMixingMatrices <> EffectiveCouplings`GetMixingMatrixFromModel[massMatrices[[i]]];
              ];
           loopCouplingsDefs = EffectiveCouplings`CreateEffectiveCouplingsDefinitions[couplings];
           loopCouplingsInit = EffectiveCouplings`CreateEffectiveCouplingsInit[couplings];
           {calculateScalarScalarLoopQCDFactor, calculateScalarFermionLoopQCDFactor,
            calculatePseudoscalarFermionLoopQCDFactor} =
               EffectiveCouplings`CalculateQCDAmplitudeScalingFactors[];
           {calculateScalarQCDScalingFactor, calculatePseudoscalarQCDScalingFactor} =
               EffectiveCouplings`CalculateQCDScalingFactor[];
           calculateLoopCouplings = EffectiveCouplings`CreateEffectiveCouplingsCalculation[couplings];
           {loopCouplingsPrototypes, loopCouplingsFunctions} =
               EffectiveCouplings`CreateEffectiveCouplings[couplings, massMatrices, vertexRules];
           WriteOut`ReplaceInFiles[files,
                                   {   "@partialWidthGetterPrototypes@" -> IndentText[partialWidthGetterPrototypes],
                                       "@partialWidthGetters@" -> partialWidthGetters,
                                       "@loopCouplingsGetters@" -> IndentText[loopCouplingsGetters],
                                       "@loopCouplingsPrototypes@" -> IndentText[loopCouplingsPrototypes],
                                       "@mixingMatricesDefs@" -> IndentText[mixingMatricesDefs],
                                       "@loopCouplingsDefs@" -> IndentText[loopCouplingsDefs],
                                       "@mixingMatricesInit@" -> IndentText[WrapLines[mixingMatricesInit]],
                                       "@loopCouplingsInit@" -> IndentText[WrapLines[loopCouplingsInit]],
                                       "@copyMixingMatrices@" -> IndentText[copyMixingMatrices],
                                       "@setSMStrongCoupling@" -> IndentText[setSMStrongCoupling],
                                       "@calculateScalarScalarLoopQCDFactor@" -> IndentText[WrapLines[calculateScalarScalarLoopQCDFactor]],
                                       "@calculateScalarFermionLoopQCDFactor@" -> IndentText[WrapLines[calculateScalarFermionLoopQCDFactor]],
                                       "@calculatePseudoscalarFermionLoopQCDFactor@" -> IndentText[WrapLines[calculatePseudoscalarFermionLoopQCDFactor]],
                                       "@calculateScalarQCDScalingFactor@" -> IndentText[WrapLines[calculateScalarQCDScalingFactor]],
                                       "@calculatePseudoscalarQCDScalingFactor@" -> IndentText[WrapLines[calculatePseudoscalarQCDScalingFactor]],
                                       "@calculateLoopCouplings@" -> IndentText[calculateLoopCouplings],
                                       "@loopCouplingsFunctions@" -> loopCouplingsFunctions,
                                       Sequence @@ GeneralReplacementRules[]
                                   } ];
          ];

(* Write the observables files *)
WriteObservables[extraSLHAOutputBlocks_, files_List] :=
    Module[{requestedObservables, numberOfObservables, observablesDef,
            observablesInit, getObservables, getObservablesNames,
            clearObservables, setObservables, calculateObservables,
            loopCouplingsPrototypes, loopCouplingsFunctions},
           requestedObservables = Observables`GetRequestedObservables[extraSLHAOutputBlocks];
           numberOfObservables = Observables`CountNumberOfObservables[requestedObservables];
           observablesDef = Observables`CreateObservablesDefinitions[requestedObservables];
           observablesInit = Observables`CreateObservablesInitialization[requestedObservables];
           {getObservables, getObservablesNames, setObservables} =
               Observables`CreateSetAndDisplayObservablesFunctions[requestedObservables];
           clearObservables = Observables`CreateClearObservablesFunction[requestedObservables];
           calculateObservables = Observables`CalculateObservables[requestedObservables, "observables"];
           WriteOut`ReplaceInFiles[files,
                                   {   "@numberOfObservables@" -> ToString[numberOfObservables],
                                       "@observablesDef@" -> IndentText[observablesDef],
                                       "@observablesInit@" -> IndentText[WrapLines[observablesInit]],
                                       "@getObservables@" -> IndentText[getObservables],
                                       "@getObservablesNames@" -> IndentText[getObservablesNames],
                                       "@clearObservables@" -> IndentText[clearObservables],
                                       "@setObservables@" -> IndentText[setObservables],
                                       "@calculateObservables@" -> IndentText[calculateObservables],
                                       Sequence @@ GeneralReplacementRules[]
                                   } ];
           ];

(* Write the GMM2 c++ files *)
WriteGMuonMinus2Class[vertexRules_List, files_List] :=
    Module[{particles, muonFunctionPrototypes, diagrams, vertexFunctionData,
        definitions, calculationCode, getMSUSY, getQED2L},
           particles = GMuonMinus2`CreateParticles[];
           muonFunctionPrototypes = GMuonMinus2`CreateMuonFunctions[vertexRules][[1]];
           diagrams = GMuonMinus2`CreateDiagrams[];
           vertexFunctionData = GMuonMinus2`CreateVertexFunctionData[vertexRules];
           definitions = GMuonMinus2`CreateDefinitions[vertexRules];
           calculationCode = GMuonMinus2`CreateCalculation[];
           getMSUSY = GMuonMinus2`GetMSUSY[];
           getQED2L = GMuonMinus2`GetQED2L[];

           WriteOut`ReplaceInFiles[files,
                                   { "@GMuonMinus2_Particles@"               -> particles,
                                     "@GMuonMinus2_MuonFunctionPrototypes@"  -> muonFunctionPrototypes,
                                     "@GMuonMinus2_Diagrams@"                -> diagrams,
                                     "@GMuonMinus2_VertexFunctionData@"      -> vertexFunctionData,
                                     "@GMuonMinus2_Definitions@"             -> definitions,
                                     "@GMuonMinus2_Calculation@"             -> IndentText[calculationCode],
                                     "@GMuonMinus2_GetMSUSY@"                -> IndentText[WrapLines[getMSUSY]],
                                     "@GMuonMinus2_QED_2L@"                  -> IndentText[WrapLines[getQED2L]],
                                       Sequence @@ GeneralReplacementRules[]
                                   } ];
           ];

GetBVPSolverHeaderName[solver_] :=
    Switch[solver,
           FlexibleSUSY`TwoScaleSolver, "two_scale",
           FlexibleSUSY`SemiAnalyticSolver, "semi_analytic",
           FlexibleSUSY`LatticeSolver, "lattice",
           _, Print["Error: invalid BVP solver requested: ", solver];
              Quit[1];
          ];

GetBVPSolverSLHAOptionKey[solver_] :=
    Switch[solver,
           FlexibleSUSY`TwoScaleSolver, "1",
           FlexibleSUSY`SemiAnalyticSolver, "2",
           FlexibleSUSY`LatticeSolver, "3",
           _, Print["Error: invalid BVP solver requested: ", solver];
              Quit[1];
          ];

GetBVPSolverTemplateParameter[solver_] :=
    Switch[solver,
           FlexibleSUSY`TwoScaleSolver, "Two_scale",
           FlexibleSUSY`SemiAnalyticSolver, "Semi_analytic",
           FlexibleSUSY`LatticeSolver, "Lattice",
           _, Print["Error: invalid BVP solver requested: ", solver];
              Quit[1];
          ];

EnableForBVPSolver[solver_, statements_String] :=
    Module[{result = "#ifdef "},
           Switch[solver,
                  FlexibleSUSY`TwoScaleSolver,
                  result = result <> "ENABLE_TWO_SCALE_SOLVER\n" <> statements,
                  FlexibleSUSY`SemiAnalyticSolver,
                  result = result <> "ENABLE_SEMI_ANALYTIC_SOLVER\n" <> statements,
                  FlexibleSUSY`LatticeSolver,
                  result = result <> "ENABLE_LATTICE_SOLVER\n" <> statements,
                  _, Print["Error: invalid BVP solver requested: ", solver];
                     Quit[1];
                 ];
           result <> "#endif"
          ];

EnableSpectrumGenerator[solver_] :=
    Module[{header = "#include \"" <> FlexibleSUSY`FSModelName},
           header = header <> "_" <> GetBVPSolverHeaderName[solver];
           header = header <> "_spectrum_generator.hpp\"\n";
           EnableForBVPSolver[solver, header] <> "\n"
          ];

RunEnabledSpectrumGenerator[solver_] :=
    Module[{key = "", class = "", macro = "", body = "", result = ""},
           key = GetBVPSolverSLHAOptionKey[solver];
           class = GetBVPSolverTemplateParameter[solver];
           body = "exit_code = run_solver<" <> class <> ">(\n"
                  <> IndentText["slha_io, spectrum_generator_settings, slha_output_file,\n"]
                  <> IndentText["database_output_file, spectrum_file, rgflow_file);\n"]
                  <> "if (!exit_code || solver_type != 0) break;\n";
           result = "case " <> key <> ":\n" <> IndentText[body];
           EnableForBVPSolver[solver, IndentText[result]] <> "\n"
          ];

ScanEnabledSpectrumGenerator[solver_] :=
    Module[{key = "", class = "", macro = "", body = "", result = ""},
           key = GetBVPSolverSLHAOptionKey[solver];
           class = GetBVPSolverTemplateParameter[solver];
           body = "result = run_parameter_point<" <> class <> ">(qedqcd, input);\n"
                  <> "if (!result.problems.have_problem() || solver_type != 0) break;\n";
           result = "case " <> key <> ":\n" <> IndentText[body];
           EnableForBVPSolver[solver, IndentText[IndentText[result]]] <> "\n"
          ];

RunCmdLineEnabledSpectrumGenerator[solver_] :=
    Module[{key = "", class = "", macro = "", body = "", result = ""},
           key = GetBVPSolverSLHAOptionKey[solver];
           class = GetBVPSolverTemplateParameter[solver];
           body = "exit_code = run_solver<" <> class <> ">(input);\n"
                  <> "if (!exit_code || solver_type != 0) break;\n";
           result = "case " <> key <> ":\n" <> IndentText[body];
           EnableForBVPSolver[solver, IndentText[result]] <> "\n"
          ];

WriteUserExample[inputParameters_List, files_List] :=
    Module[{parseCmdLineOptions, printCommandLineOptions, inputPars,
            solverIncludes = "", runEnabledSolvers = "", scanEnabledSolvers = "",
            runEnabledCmdLineSolvers = "", defaultSolverType},
           inputPars = {First[#], #[[3]]}& /@ inputParameters;
           parseCmdLineOptions = WriteOut`ParseCmdLineOptions[inputPars];
           printCommandLineOptions = WriteOut`PrintCmdLineOptions[inputPars];
           (solverIncludes = solverIncludes <> EnableSpectrumGenerator[#])& /@ FlexibleSUSY`FSBVPSolvers;
           (runEnabledSolvers = runEnabledSolvers <> RunEnabledSpectrumGenerator[#])& /@ FlexibleSUSY`FSBVPSolvers;
           (scanEnabledSolvers = scanEnabledSolvers <> ScanEnabledSpectrumGenerator[#])& /@ FlexibleSUSY`FSBVPSolvers;
           (runEnabledCmdLineSolvers = runEnabledCmdLineSolvers <> RunCmdLineEnabledSpectrumGenerator[#])& /@ FlexibleSUSY`FSBVPSolvers;
           If[Length[FlexibleSUSY`FSBVPSolvers] == 0,
              defaultSolverType = "-1",
              defaultSolverType = GetBVPSolverSLHAOptionKey[FlexibleSUSY`FSBVPSolvers[[1]]]
             ];
           WriteOut`ReplaceInFiles[files,
                          { "@parseCmdLineOptions@" -> IndentText[IndentText[parseCmdLineOptions]],
                            "@printCommandLineOptions@" -> IndentText[IndentText[printCommandLineOptions]],
                            "@solverIncludes@" -> solverIncludes,
                            "@runEnabledSolvers@" -> runEnabledSolvers,
                            "@scanEnabledSolvers@" -> scanEnabledSolvers,
                            "@runEnabledCmdLineSolvers@" -> runEnabledCmdLineSolvers,
                            "@defaultSolverType@" -> defaultSolverType,
                            Sequence @@ GeneralReplacementRules[]
                          } ];
          ];

EnableMathlinkSpectrumGenerator[solver_] :=
    Module[{type, headers = ""},
           type = GetBVPSolverHeaderName[solver];
           headers = "#include \"" <> FlexibleSUSY`FSModelName <> "_" <> type <> "_model.hpp\"\n";
           headers = headers <> "#include \"" <> FlexibleSUSY`FSModelName <> "_" <> type <> "_spectrum_generator.hpp\"\n";
           EnableForBVPSolver[solver, headers] <> "\n"
          ];

RunEnabledModelType[solver_] :=
    Module[{key, class, body, result},
           key = GetBVPSolverSLHAOptionKey[solver];
           class = GetBVPSolverTemplateParameter[solver];
           body = "spectrum.reset(new " <> FlexibleSUSY`FSModelName <>
                  "_spectrum_impl<" <> class <> ">());\n"
                  <> "spectrum->calculate_spectrum(settings, modsel, qedqcd, input);\n"
                  <> "if (!spectrum->get_problems().have_problem() || solver_type != 0) break;\n";
           result = "case " <> key <> ":\n" <> IndentText[body];
           EnableForBVPSolver[solver, IndentText[result]] <> "\n"
          ];

WriteMathLink[inputParameters_List, extraSLHAOutputBlocks_List, files_List] :=
    Module[{numberOfInputParameters, numberOfInputParameterRules,
            putInputParameters,
            setInputParameterDefaultArguments,
            setInputParameterArguments,
            numberOfSpectrumEntries, putSpectrum, setInputParameters,
            numberOfObservables, putObservables,
            listOfInputParameters, listOfModelParameters, listOfOutputParameters,
            inputPars, outPars, requestedObservables, defaultSolverType,
            solverIncludes = "", runEnabledSolvers = ""},
           inputPars = {#[[1]], #[[3]]}& /@ inputParameters;
           numberOfInputParameters = Total[CConversion`CountNumberOfEntries[#[[2]]]& /@ inputPars];
           numberOfInputParameterRules = FSMathLink`GetNumberOfInputParameterRules[inputPars];
           putInputParameters = FSMathLink`PutInputParameters[inputPars, "link"];
           setInputParameters = FSMathLink`SetInputParametersFromArguments[inputPars];
           setInputParameterDefaultArguments = FSMathLink`SetInputParameterDefaultArguments[inputPars];
           setInputParameterArguments = FSMathLink`SetInputParameterArguments[inputPars];
           outPars = Parameters`GetOutputParameters[] /. FlexibleSUSY`M[p_List] :> Sequence @@ (FlexibleSUSY`M /@ p);
           outPars = Join[outPars, FlexibleSUSY`Pole /@ outPars, Parameters`GetModelParameters[],
                          Parameters`GetExtraParameters[], {FlexibleSUSY`SCALE}];
           listOfInputParameters = ToString[First /@ inputParameters];
           listOfOutputParameters = ToString[outPars];
           listOfModelParameters = ToString[Parameters`GetModelParameters[]];
           numberOfSpectrumEntries = FSMathLink`GetNumberOfSpectrumEntries[outPars];
           putSpectrum = FSMathLink`PutSpectrum[outPars, "link"];
           (* get observables *)
           requestedObservables = Observables`GetRequestedObservables[extraSLHAOutputBlocks];
           numberOfObservables = Length[requestedObservables];
           putObservables = FSMathLink`PutObservables[requestedObservables, "link"];
           (solverIncludes = solverIncludes <> EnableMathlinkSpectrumGenerator[#])& /@ FlexibleSUSY`FSBVPSolvers;
           (runEnabledSolvers = runEnabledSolvers <> RunEnabledModelType[#])& /@ FlexibleSUSY`FSBVPSolvers;
           If[Length[FlexibleSUSY`FSBVPSolvers] == 0,
              defaultSolverType = "-1",
              defaultSolverType = GetBVPSolverSLHAOptionKey[FlexibleSUSY`FSBVPSolvers[[1]]];
             ];
           WriteOut`ReplaceInFiles[files,
                          { "@numberOfInputParameters@" -> ToString[numberOfInputParameters],
                            "@numberOfInputParameterRules@" -> ToString[numberOfInputParameterRules],
                            "@putInputParameters@" -> IndentText[putInputParameters],
                            "@setInputParameters@" -> IndentText[setInputParameters],
                            "@setInputParameterArguments@" -> IndentText[setInputParameterArguments, 12],
                            "@setInputParameterDefaultArguments@" -> IndentText[setInputParameterDefaultArguments],
                            "@setDefaultInputParameters@" -> IndentText[setInputParameterDefaultArguments,8],
                            "@numberOfSpectrumEntries@" -> ToString[numberOfSpectrumEntries],
                            "@putSpectrum@" -> IndentText[putSpectrum],
                            "@numberOfObservables@" -> ToString[numberOfObservables],
                            "@putObservables@" -> IndentText[putObservables],
                            "@listOfInputParameters@" -> listOfInputParameters,
                            "@listOfModelParameters@" -> listOfModelParameters,
                            "@listOfOutputParameters@" -> listOfOutputParameters,
                            "@solverIncludes@" -> solverIncludes,
                            "@runEnabledSolvers@" -> runEnabledSolvers,
                            "@defaultSolverType@" -> defaultSolverType,
                            Sequence @@ GeneralReplacementRules[]
                          } ];
          ];

WritePlotScripts[files_List] :=
    Module[{},
           WriteOut`ReplaceInFiles[files,
                          { Sequence @@ GeneralReplacementRules[]
                          } ];
          ];

WriteSLHAInputFile[inputParameters_List, files_List] :=
    Module[{formattedSLHAInputBlocks},
           formattedSLHAInputBlocks = CreateFormattedSLHABlocks[inputParameters];
           WriteOut`ReplaceInFiles[files,
                          { "@formattedSLHAInputBlocks@" -> formattedSLHAInputBlocks,
                            Sequence @@ GeneralReplacementRules[]
                          } ];
          ];

WriteMakefileModule[rgeFile_List, files_List] :=
    Module[{concatenatedFileList},
           concatenatedFileList = "\t" <> Utils`StringJoinWithSeparator[rgeFile, " \\\n\t"];
           WriteOut`ReplaceInFiles[files,
                          { "@generatedBetaFunctionModules@" -> concatenatedFileList,
                            Sequence @@ GeneralReplacementRules[]
                          } ];
          ];

WriteBVPSolverMakefile[files_List] :=
    Module[{twoScaleSource = "", twoScaleHeader = "",
            semiAnalyticSource = "", semiAnalyticHeader = ""},
           If[FlexibleSUSY`FlexibleEFTHiggs === True,
              twoScaleSource = "\t\t" <> FileNameJoin[{FSOutputDir, FlexibleSUSY`FSModelName <> "_standard_model_two_scale_matching.cpp"}];
              twoScaleHeader = "\t\t" <> FileNameJoin[{FSOutputDir, FlexibleSUSY`FSModelName <> "_standard_model_two_scale_matching.hpp"}];
              semiAnalyticSource = "\t\t" <> FileNameJoin[{FSOutputDir, FlexibleSUSY`FSModelName <> "_standard_model_semi_analytic_matching.cpp"}];
              semiAnalyticHeader = "\t\t" <> FileNameJoin[{FSOutputDir, FlexibleSUSY`FSModelName <> "_standard_model_semi_analytic_matching.hpp"}];

             ];
           WriteOut`ReplaceInFiles[files,
                   { "@FlexibleEFTHiggsTwoScaleSource@" -> twoScaleSource,
                     "@FlexibleEFTHiggsTwoScaleHeader@" -> twoScaleHeader,
                     "@FlexibleEFTHiggsSemiAnalyticSource@" -> semiAnalyticSource,
                     "@FlexibleEFTHiggsSemiAnalyticHeader@" -> semiAnalyticHeader,
                     Sequence @@ GeneralReplacementRules[]
                   } ];
          ];

WriteUtilitiesClass[massMatrices_List, betaFun_List, inputParameters_List,
                    lesHouchesParameters_List, extraSLHAOutputBlocks_List, files_List] :=
    Module[{k, particles, susyParticles, smParticles,
            minpar, extpar, imminpar, imextpar, extraSLHAInputParameters,
            fillSpectrumVectorWithSusyParticles = "",
            fillSpectrumVectorWithSMParticles = "",
            particleLaTeXNames = "",
            particleNames = "", particleEnum = "", particleMassEnum, particleMultiplicity = "",
            particleMixingEnum = "", particleMixingNames = "",
            parameterNames = "", parameterEnum = "", numberOfParameters = 0,
            inputParameterEnum = "", inputParameterNames = "",
            isLowEnergyModel = "false",
            isSupersymmetricModel = "false",
            isFlexibleEFTHiggs = "false",
            fillInputParametersFromMINPAR = "", fillInputParametersFromEXTPAR = "",
            fillInputParametersFromIMMINPAR = "",
            fillInputParametersFromIMEXTPAR = "",
            writeSLHAMassBlock = "", writeSLHAMixingMatricesBlocks = "",
            writeSLHAModelParametersBlocks = "", writeSLHAPhasesBlocks = "",
            writeSLHAMinparBlock = "", writeSLHAExtparBlock = "",
            writeSLHAImMinparBlock = "", writeSLHAImExtparBlock = "",
            writeSLHAInputParameterBlocks = "",
            readLesHouchesInputParameters, writeExtraSLHAOutputBlock = "",
            readLesHouchesOutputParameters, readLesHouchesPhysicalParameters,
            gaugeCouplingNormalizationDecls = "",
            gaugeCouplingNormalizationDefs = "",
            numberOfDRbarBlocks, drBarBlockNames
           },
           particles = DeleteDuplicates @ Flatten[TreeMasses`GetMassEigenstate /@ massMatrices];
           susyParticles = Select[particles, (!TreeMasses`IsSMParticle[#])&];
           smParticles   = Complement[particles, susyParticles];
           minpar = Cases[inputParameters, {p_, {"MINPAR", idx_}, ___} :> {idx, p}];
           extpar = Cases[inputParameters, {p_, {"EXTPAR", idx_}, ___} :> {idx, p}];
           imminpar = Cases[inputParameters, {p_, {"IMMINPAR", idx_}, ___} :> {idx, p}];
           imextpar = Cases[inputParameters, {p_, {"IMEXTPAR", idx_}, ___} :> {idx, p}];
           extraSLHAInputParameters = Complement[
               inputParameters,
               Cases[inputParameters, {_, {"MINPAR", _}, ___}],
               Cases[inputParameters, {_, {"EXTPAR", _}, ___}],
               Cases[inputParameters, {_, {"IMMINPAR", _}, ___}],
               Cases[inputParameters, {_, {"IMEXTPAR", _}, ___}]
           ];
           particleEnum       = TreeMasses`CreateParticleEnum[particles];
           particleMassEnum   = TreeMasses`CreateParticleMassEnum[particles];
           particleMixingEnum = TreeMasses`CreateParticleMixingEnum[massMatrices];
           particleMultiplicity = TreeMasses`CreateParticleMultiplicity[particles];
           particleNames      = TreeMasses`CreateParticleNames[particles];
           particleLaTeXNames = TreeMasses`CreateParticleLaTeXNames[particles];
           particleMixingNames= TreeMasses`CreateParticleMixingNames[massMatrices];
           inputParameterEnum  = Parameters`CreateInputParameterEnum[inputParameters];
           inputParameterNames = Parameters`CreateInputParameterNames[inputParameters];
           fillSpectrumVectorWithSusyParticles = TreeMasses`FillSpectrumVector[susyParticles];
           fillSpectrumVectorWithSMParticles   = TreeMasses`FillSpectrumVector[smParticles];
           numberOfParameters = BetaFunction`CountNumberOfParameters[betaFun];
           parameterEnum      = BetaFunction`CreateParameterEnum[betaFun];
           parameterNames     = BetaFunction`CreateParameterNames[betaFun];
           isLowEnergyModel = If[FlexibleSUSY`OnlyLowEnergyFlexibleSUSY === True, "true", "false"];
           isSupersymmetricModel = If[SARAH`SupersymmetricModel === True, "true", "false"];
           isFlexibleEFTHiggs = If[FlexibleSUSY`FlexibleEFTHiggs === True, "true", "false"];
           fillInputParametersFromMINPAR = Parameters`FillInputParametersFromTuples[minpar, "MINPAR"];
           fillInputParametersFromEXTPAR = Parameters`FillInputParametersFromTuples[extpar, "EXTPAR"];
           fillInputParametersFromIMMINPAR = Parameters`FillInputParametersFromTuples[imminpar, "IMMINPAR"];
           fillInputParametersFromIMEXTPAR = Parameters`FillInputParametersFromTuples[imextpar, "IMEXTPAR"];
           readLesHouchesInputParameters = WriteOut`ReadLesHouchesInputParameters[{First[#], #[[2]]}& /@ extraSLHAInputParameters];
           readLesHouchesOutputParameters = WriteOut`ReadLesHouchesOutputParameters[lesHouchesParameters];
           readLesHouchesPhysicalParameters = WriteOut`ReadLesHouchesPhysicalParameters[lesHouchesParameters, "LOCALPHYSICAL",
                                                                                        "DEFINE_PHYSICAL_PARAMETER"];
           writeSLHAMassBlock = WriteOut`WriteSLHAMassBlock[massMatrices];
           writeSLHAMixingMatricesBlocks  = WriteOut`WriteSLHAMixingMatricesBlocks[lesHouchesParameters];
           writeSLHAModelParametersBlocks = WriteOut`WriteSLHAModelParametersBlocks[lesHouchesParameters];
           writeSLHAPhasesBlocks = WriteOut`WriteSLHAPhasesBlocks[lesHouchesParameters];
           writeSLHAMinparBlock = WriteOut`WriteSLHAMinparBlock[minpar];
           writeSLHAExtparBlock = WriteOut`WriteSLHAExtparBlock[extpar];
           writeSLHAImMinparBlock = WriteOut`WriteSLHAImMinparBlock[imminpar];
           writeSLHAImExtparBlock = WriteOut`WriteSLHAImExtparBlock[imextpar];
           writeSLHAInputParameterBlocks = WriteSLHAInputParameterBlocks[extraSLHAInputParameters];
           writeExtraSLHAOutputBlock = WriteOut`WriteExtraSLHAOutputBlock[extraSLHAOutputBlocks];
           numberOfDRbarBlocks  = WriteOut`GetNumberOfDRbarBlocks[lesHouchesParameters];
           drBarBlockNames      = WriteOut`GetDRbarBlockNames[lesHouchesParameters];
           gaugeCouplingNormalizationDecls = WriteOut`GetGaugeCouplingNormalizationsDecls[SARAH`Gauge];
           gaugeCouplingNormalizationDefs  = WriteOut`GetGaugeCouplingNormalizationsDefs[SARAH`Gauge];
           WriteOut`ReplaceInFiles[files,
                          { "@fillSpectrumVectorWithSusyParticles@" -> IndentText[fillSpectrumVectorWithSusyParticles],
                            "@fillSpectrumVectorWithSMParticles@"   -> IndentText[IndentText[fillSpectrumVectorWithSMParticles]],
                            "@particleEnum@"       -> IndentText[WrapLines[particleEnum]],
                            "@particleMassEnum@"   -> IndentText[WrapLines[particleMassEnum]],
                            "@particleMixingEnum@" -> IndentText[WrapLines[particleMixingEnum]],
                            "@particleMultiplicity@" -> IndentText[WrapLines[particleMultiplicity]],
                            "@particleNames@"      -> IndentText[WrapLines[particleNames]],
                            "@particleLaTeXNames@" -> IndentText[WrapLines[particleLaTeXNames]],
                            "@parameterEnum@"     -> IndentText[WrapLines[parameterEnum]],
                            "@parameterNames@"     -> IndentText[WrapLines[parameterNames]],
                            "@particleMixingNames@"-> IndentText[WrapLines[particleMixingNames]],
                            "@inputParameterEnum@" -> IndentText[WrapLines[inputParameterEnum]],
                            "@inputParameterNames@"-> IndentText[WrapLines[inputParameterNames]],
                            "@isLowEnergyModel@"   -> isLowEnergyModel,
                            "@isSupersymmetricModel@" -> isSupersymmetricModel,
                            "@isFlexibleEFTHiggs@" -> isFlexibleEFTHiggs,
                            "@fillInputParametersFromMINPAR@" -> IndentText[fillInputParametersFromMINPAR],
                            "@fillInputParametersFromEXTPAR@" -> IndentText[fillInputParametersFromEXTPAR],
                            "@fillInputParametersFromIMMINPAR@" -> IndentText[fillInputParametersFromIMMINPAR],
                            "@fillInputParametersFromIMEXTPAR@" -> IndentText[fillInputParametersFromIMEXTPAR],
                            "@readLesHouchesInputParameters@" -> IndentText[readLesHouchesInputParameters],
                            "@readLesHouchesOutputParameters@" -> IndentText[readLesHouchesOutputParameters],
                            "@readLesHouchesPhysicalParameters@" -> IndentText[readLesHouchesPhysicalParameters],
                            "@writeSLHAMassBlock@" -> IndentText[writeSLHAMassBlock],
                            "@writeSLHAMixingMatricesBlocks@"  -> IndentText[writeSLHAMixingMatricesBlocks],
                            "@writeSLHAModelParametersBlocks@" -> IndentText[writeSLHAModelParametersBlocks],
                            "@writeSLHAPhasesBlocks@"          -> IndentText[writeSLHAPhasesBlocks],
                            "@writeSLHAMinparBlock@"           -> IndentText[writeSLHAMinparBlock],
                            "@writeSLHAExtparBlock@"           -> IndentText[writeSLHAExtparBlock],
                            "@writeSLHAImMinparBlock@"         -> IndentText[writeSLHAImMinparBlock],
                            "@writeSLHAImExtparBlock@"         -> IndentText[writeSLHAImExtparBlock],
                            "@writeSLHAInputParameterBlocks@"  -> IndentText[writeSLHAInputParameterBlocks],
                            "@writeExtraSLHAOutputBlock@"      -> IndentText[writeExtraSLHAOutputBlock],
                            "@gaugeCouplingNormalizationDecls@"-> IndentText[gaugeCouplingNormalizationDecls],
                            "@gaugeCouplingNormalizationDefs@" -> IndentText[gaugeCouplingNormalizationDefs],
                            "@numberOfDRbarBlocks@"            -> ToString[numberOfDRbarBlocks],
                            "@drBarBlockNames@"                -> WrapLines[drBarBlockNames],
                            Sequence @@ GeneralReplacementRules[]
                          } ];
          ];

FilesExist[fileNames_List] :=
    And @@ (FileExistsQ /@ fileNames);

LatestModificationTimeInSeconds[file_String] :=
    If[FileExistsQ[file],
       AbsoluteTime[FileDate[file, "Modification"]], 0];

LatestModificationTimeInSeconds[files_List] :=
    Max[LatestModificationTimeInSeconds /@ files];

SARAHModelFileModificationTimeInSeconds[] :=
    LatestModificationTimeInSeconds @ \
    Join[{SARAH`ModelFile},
         FileNameJoin[{$sarahCurrentModelDir, #}]& /@ {"parameters.m", "particles.m"}];

GetRGEFileNames[outputDir_String] :=
    Module[{rgeDir, fileNames},
           rgeDir = FileNameJoin[{outputDir, "RGEs"}];
           fileNames = { "BetaYijk.m", "BetaGauge.m", "BetaMuij.m",
                         "BetaTijk.m", "BetaBij.m", "BetaVEV.m" };
           If[SARAH`AddDiracGauginos === True,
              AppendTo[fileNames, "BetaDGi.m"];
             ];
           If[SARAH`SupersymmetricModel === False,
              AppendTo[fileNames, "BetaLijkl.m"];
             ];
           If[SARAH`SupersymmetricModel === True,
              fileNames = Join[fileNames,
                               { "BetaWijkl.m", "BetaQijkl.m", "BetaLSi.m",
                                 "BetaLi.m", "Betam2ij.m", "BetaMi.m" }];
             ];
           FileNameJoin[{rgeDir, #}]& /@ fileNames
          ];

GetSelfEnergyFileNames[outputDir_String, eigenstates_] :=
    FileNameJoin[{outputDir, ToString[eigenstates],
                  "One-Loop", "SelfEnergy.m"}];

NeedToCalculateSelfEnergies[eigenstates_] :=
    NeedToUpdateTarget[
        "self-energy",
        GetSelfEnergyFileNames[$sarahCurrentOutputMainDir, eigenstates]];

GetTadpoleFileName[outputDir_String, eigenstates_] :=
    FileNameJoin[{outputDir, ToString[eigenstates],
                  "One-Loop", "Tadpoles1Loop.m"}];

NeedToCalculateTadpoles[eigenstates_] :=
    NeedToUpdateTarget[
        "tadpole",
        GetTadpoleFileName[$sarahCurrentOutputMainDir, eigenstates]];

GetUnrotatedParticlesFileName[outputDir_String, eigenstates_] :=
    FileNameJoin[{outputDir, ToString[eigenstates],
                  "One-Loop", "UnrotatedParticles.m"}];

NeedToCalculateUnrotatedParticles[eigenstates_] :=
    NeedToUpdateTarget[
        "unrotated particle",
        GetUnrotatedParticlesFileName[$sarahCurrentOutputMainDir,eigenstates]];

NeedToCalculateRGEs[] :=
    NeedToUpdateTarget["RGE", GetRGEFileNames[$sarahCurrentOutputMainDir]];

GetVertexRuleFileName[outputDir_String, eigenstates_] :=
    FileNameJoin[{outputDir, ToString[eigenstates], "Vertices",
                  "FSVertexRules.m"}];

GetEffectiveCouplingsFileName[outputDir_String, eigenstates_] :=
    FileNameJoin[{outputDir, ToString[eigenstates], "Vertices",
                  "FSEffectiveCouplings.m"}];

NeedToCalculateVertices[eigenstates_] :=
    NeedToUpdateTarget[
        "vertex",
        { GetVertexRuleFileName[$sarahCurrentOutputMainDir, eigenstates],
          GetEffectiveCouplingsFileName[$sarahCurrentOutputMainDir, eigenstates] }];

NeedToUpdateTarget[name_String, targets_List] := Module[{
        targetsExist = FilesExist[targets],
        targetTimeStamp = LatestModificationTimeInSeconds[targets],
        sarahModelFileTimeStamp = SARAHModelFileModificationTimeInSeconds[],
        files = If[Length[targets] === 1, "file", "files"],
        them = If[Length[targets] === 1, "it", "them"]
    },
    If[targetsExist,
       If[sarahModelFileTimeStamp > targetTimeStamp,
          Print["SARAH model files are newer than ", name,
                " ", files, ", updating ", them, " ..."];
          True,
          Print["Found up-to-date ", name, " ", files, "."];
          False
       ],
       Print[name, " ", files, " not found, producing ", them, " ..."];
       True
    ]
];

NeedToUpdateTarget[name_String, target_] :=
    NeedToUpdateTarget[name, {target}];

FSPrepareRGEs[loopOrder_] :=
    Module[{needToCalculateRGEs, betas},
           If[loopOrder > 0,
              needToCalculateRGEs = NeedToCalculateRGEs[];
              SARAH`CalcRGEs[ReadLists -> !needToCalculateRGEs,
                             TwoLoop -> If[loopOrder < 2, False, True],
                             NoMatrixMultiplication -> False];
              ,
              (* create Beta* symbols with beta functions set to 0 *)
              SARAH`MakeDummyListRGEs[];
             ];
           (* check if the beta functions were calculated correctly *)
           betas = { SARAH`BetaWijkl, SARAH`BetaYijk, SARAH`BetaMuij,
                     SARAH`BetaLi, SARAH`BetaGauge, SARAH`BetaVEV,
                     SARAH`BetaQijkl, SARAH`BetaTijk, SARAH`BetaBij,
                     SARAH`BetaLSi, SARAH`Betam2ij, SARAH`BetaMi,
                     SARAH`BetaDGi, SARAH`BetaLijkl };
           If[Head[#] === Symbol && !ValueQ[#], Set[#,{}]]& /@ betas;
           If[!ValueQ[SARAH`Gij] || Head[SARAH`Gij] =!= List,
              SARAH`Gij = {};
             ];
          ];

FSCheckLoopCorrections[eigenstates_] :=
    Module[{needToCalculateLoopCorrections},
           needToCalculateLoopCorrections = Or[
               NeedToCalculateSelfEnergies[eigenstates],
               NeedToCalculateTadpoles[eigenstates],
               NeedToCalculateUnrotatedParticles[eigenstates]
                                              ];
           If[needToCalculateLoopCorrections,
              SARAH`CalcLoopCorrections[eigenstates];
             ];
          ];

PrepareSelfEnergies[eigenstates_] :=
    Module[{selfEnergies = {}, selfEnergiesFile},
           selfEnergiesFile = GetSelfEnergyFileNames[$sarahCurrentOutputMainDir, eigenstates];
           If[!FileExistsQ[selfEnergiesFile],
              Print["Error: self-energy files not found: ", selfEnergiesFile];
              Quit[1];
             ];
           Print["Reading self-energies from file ", selfEnergiesFile, " ..."];
           selfEnergies = Get[selfEnergiesFile];
           Print["Converting self-energies ..."];
           ConvertSarahSelfEnergies[selfEnergies]
          ];

PrepareTadpoles[eigenstates_] :=
    Module[{tadpoles = {}, tadpolesFile},
           tadpolesFile = GetTadpoleFileName[$sarahCurrentOutputMainDir, eigenstates];
           If[!FilesExist[tadpolesFile],
              Print["Error: tadpole file not found: ", tadpolesFile];
              Quit[1];
             ];
           Print["Reading tadpoles from file ", tadpolesFile, " ..."];
           tadpoles = Get[tadpolesFile];
           Print["Converting tadpoles ..."];
           ConvertSarahTadpoles[tadpoles]
          ];

(* Get all nPointFunctions that GMM2 needs *)
PrepareGMuonMinus2[] := GMuonMinus2`NPointFunctions[];

PrepareUnrotatedParticles[eigenstates_] :=
    Module[{nonMixedParticles = {}, nonMixedParticlesFile},
           nonMixedParticlesFile = GetUnrotatedParticlesFileName[$sarahCurrentOutputMainDir, eigenstates];
           If[!FilesExist[nonMixedParticlesFile],
              Print["Error: file with unrotated fields not found: ", nonMixedParticlesFile];
              Quit[1];
             ];
           Print["Reading unrotated particles from file ", nonMixedParticlesFile, " ..."];
           nonMixedParticles = Get[nonMixedParticlesFile];
           DebugPrint["unrotated particles: ", nonMixedParticles];
           TreeMasses`SetUnrotatedParticles[nonMixedParticles];
          ];

PrepareEWSBEquations[indexReplacementRules_] :=
    Module[{ewsbEquations},
           ewsbEquations = SARAH`TadpoleEquations[FSEigenstates] /.
                           Parameters`ApplyGUTNormalization[] /.
                           indexReplacementRules /.
                           SARAH`sum[idx_, start_, stop_, expr_] :> Sum[expr, {idx,start,stop}];
           If[Head[ewsbEquations] =!= List,
              Print["Error: Could not find EWSB equations for eigenstates ",
                    FSEigenstates];
              Quit[1];
             ];
           (* filter out trivial EWSB eqs. *)
           ewsbEquations = Select[ewsbEquations, (#=!=0)&];
           ewsbEquations = Parameters`ExpandExpressions[ewsbEquations];
           (* add tadpoles to the EWSB eqs. *)
           MapIndexed[#1 - tadpole[First[#2]]&, ewsbEquations]
          ];


AddEWSBSubstitutionsForSolver[solver_, currentSubs_, extraSubs_] :=
    Module[{pos, oldSubs, newSubs},
           pos = Position[currentSubs, solver -> subs_];
           If[pos === {},
              newSubs = Append[currentSubs, Rule[solver, extraSubs]];,
              oldSubs = Extract[currentSubs, pos][[1,-1]];
              newSubs = ReplacePart[currentSubs, pos -> Rule[solver, Join[oldSubs, extraSubs]]];
             ];
           newSubs
          ];

SolveEWSBEquations[ewsbEquations_, ewsbOutputParameters_, ewsbSubstitutions_, treeLevelSolution_, treeLevelEwsbSolutionOutputFile_] :=
    Module[{i, independentEwsbEquations, ewsbSolution, freePhases},
           Print["Searching for independent EWSB equations ..."];
           independentEwsbEquations = EWSB`GetLinearlyIndependentEqs[ewsbEquations, ewsbOutputParameters,
                                                                     ewsbSubstitutions];
           If[treeLevelSolution === {},
              (* trying to find an analytic solution for the EWSB eqs. *)
              Print["Solving ", Length[independentEwsbEquations],
                    " independent EWSB equations for ",
                    ewsbOutputParameters, " ..."];
              {ewsbSolution, freePhases} = EWSB`FindSolutionAndFreePhases[independentEwsbEquations,
                                                                          ewsbOutputParameters,
                                                                          treeLevelEwsbSolutionOutputFile,
                                                                          ewsbSubstitutions];
              Print["   The EWSB solution was written to the file:"];
              Print["      ", treeLevelEwsbSolutionOutputFile];
             ,
              If[Length[treeLevelSolution] != Length[independentEwsbEquations],
                 Print["Error: not enough EWSB solutions given!"];
                 Print["   You provided solutions for ", Length[treeLevelSolution],
                       " parameters."];
                 Print["   However, there are ", Length[independentEwsbEquations],
                       " independent EWSB eqs."];
                 Quit[1];
                ];
              If[Sort[#[[1]]& /@ treeLevelSolution] =!= Sort[ewsbOutputParameters],
                 Print["Error: Parameters given in TreeLevelEWSBSolution, do not match"];
                 Print["   the Parameters given in FlexibleSUSY`EWSBOutputParameters!"];
                 Quit[1];
                ];
              Print["Using user-defined EWSB eqs. solution"];
              freePhases = {};
              ewsbSolution = Rule[#[[1]], #[[2]]]& /@ treeLevelSolution;
             ];
           {ewsbSolution, freePhases}
          ];

SolveEWSBEquationsForSolvers[solvers_List, ewsbEquations_, ewsbOutputParameters_,
                             solverSubstitutions_, treeLevelSolution_, solutionOutputFiles_] :=
    Module[{i, solver, substitutions, outputFile, solution, freePhases,
            allSolutions = {}, allFreePhases = {}},
           For[i = 1, i <= Length[solvers], i++,
               solver = solvers[[i]];
               substitutions = solver /. solverSubstitutions;
               outputFile = solver /. solutionOutputFiles;
               {solution, freePhases} = SolveEWSBEquations[ewsbEquations, ewsbOutputParameters,
                                                           substitutions, treeLevelSolution, outputFile];
               allSolutions = Append[allSolutions, solver -> solution];
               allFreePhases = Append[allFreePhases, solver -> freePhases];
              ];
           {allSolutions, allFreePhases}
          ];

SelectValidEWSBSolvers[solverSolutions_, ewsbSolvers_] :=
    Module[{i, solver, solution, validSolvers, solverEwsbSolvers = {}},
           For[i = 1, i <= Length[solverSolutions], i++,
               solver = First[solverSolutions[[i]]];
               solution = Last[solverSolutions[[i]]];
               validSolvers = ewsbSolvers;
               If[solution === {},
                  (* Fixed-point iteration can only be used if an analytic EWSB solution exists *)
                  If[MemberQ[validSolvers, FlexibleSUSY`FPIRelative],
                     Print["Warning: FPIRelative was selected, but no analytic"];
                     Print["   solution to the EWSB eqs. is provided."];
                     Print["   FPIRelative will be removed from the list of EWSB solvers."];
                     validSolvers = Cases[validSolvers, Except[FlexibleSUSY`FPIRelative]];
                    ];
                  If[MemberQ[validSolvers, FlexibleSUSY`FPIAbsolute],
                     Print["Warning: FPIAbsolute was selected, but no analytic"];
                     Print["   solution to the EWSB eqs. is provided."];
                     Print["   FPIAbsolute will be removed from the list of EWSB solvers."];
                     validSolvers = Cases[validSolvers, Except[FlexibleSUSY`FPIAbsolute]];
                    ];
                 ];
               solverEwsbSolvers = Append[solverEwsbSolvers, solver -> validSolvers];
              ];
           solverEwsbSolvers
          ];

GetAllFreePhases[solverFreePhases_List] := DeleteDuplicates[Flatten[#[[2]]& /@ solverFreePhases]];

ReadPoleMassPrecisions[defaultPrecision_Symbol, highPrecisionList_List,
                       mediumPrecisionList_List, lowPrecisionList_List, eigenstates_] :=
    Module[{particles, particle, i, precisionList = {}, higgs},
           If[!MemberQ[{LowPrecision, MediumPrecision, HighPrecision}, defaultPrecision],
              Print["Error: ", defaultPrecision, " is not a valid",
                    " diagonalization precision!"];
              Print["   Available are: LowPrecision, MediumPrecision, HighPrecision"];
              Quit[1];
             ];
           particles = LoopMasses`GetLoopCorrectedParticles[eigenstates];
           For[i = 1, i <= Length[particles], i++,
               particle = particles[[i]];
               Which[MemberQ[highPrecisionList  , particle], AppendTo[precisionList, {particle, HighPrecision}],
                     MemberQ[mediumPrecisionList, particle], AppendTo[precisionList, {particle, MediumPrecision}],
                     MemberQ[lowPrecisionList   , particle], AppendTo[precisionList, {particle, LowPrecision}],
                     True, AppendTo[precisionList, {particle, defaultPrecision}]
                    ];
              ];
           higgs = Cases[precisionList, {SARAH`HiggsBoson | SARAH`PseudoScalar | SARAH`ChargedHiggs, LowPrecision}];
           Message[ReadPoleMassPrecisions::ImpreciseHiggs, #[[1]], #[[2]]]& /@ higgs;
           Return[precisionList];
          ];

LoadModelFile[file_String] :=
    Module[{},
           PrintHeadline["Loading FlexibleSUSY model file"];
           If[FileExistsQ[file],
              Get[file];
              CheckModelFileSettings[];
              ,
              Print["Error: model file not found: ", file];
              Quit[1];
             ];
          ];

StripSARAHIndices[expr_, numToStrip_Integer:4] :=
    Module[{i, rules, result = expr},
           rules = Table[Parameters`StripSARAHIndicesRules[i], {i, 1, numToStrip}];
           For[i = 1, i <= numToStrip, i++,
               result = result /. rules[[i]];
              ];
           result
          ];

EnsureSMGaugeCouplingsSet[] :=
    Block[{},
          If[ValueQ[SARAH`hyperchargeCoupling] &&
             !Constraint`IsFixed[SARAH`hyperchargeCoupling,
                                 Join[FlexibleSUSY`LowScaleInput,
                                      FlexibleSUSY`SUSYScaleInput,
                                      FlexibleSUSY`HighScaleInput]],
             AppendTo[FlexibleSUSY`LowScaleInput,
                      {SARAH`hyperchargeCoupling, "new_g1"}];
            ];
          If[ValueQ[SARAH`leftCoupling] &&
             !Constraint`IsFixed[SARAH`leftCoupling,
                                 Join[FlexibleSUSY`LowScaleInput,
                                      FlexibleSUSY`SUSYScaleInput,
                                      FlexibleSUSY`HighScaleInput]],
             AppendTo[FlexibleSUSY`LowScaleInput,
                      {SARAH`leftCoupling, "new_g2"}];
            ];
          If[ValueQ[SARAH`strongCoupling] &&
             !Constraint`IsFixed[SARAH`strongCoupling,
                                 Join[FlexibleSUSY`LowScaleInput,
                                      FlexibleSUSY`SUSYScaleInput,
                                      FlexibleSUSY`HighScaleInput]],
             AppendTo[FlexibleSUSY`LowScaleInput,
                      {SARAH`strongCoupling, "new_g3"}];
            ];
         ];

EnsureEWSBConstraintApplied[] :=
    Block[{},
          If[FlexibleSUSY`FlexibleEFTHiggs === True,
             If[FreeQ[Join[FlexibleSUSY`SUSYScaleInput, FlexibleSUSY`HighScaleInput],
                      FlexibleSUSY`FSSolveEWSBFor[___]],
                AppendTo[FlexibleSUSY`SUSYScaleInput,
                         FlexibleSUSY`FSSolveEWSBFor[FlexibleSUSY`EWSBOutputParameters]];
                ];
             ,
             If[FreeQ[Join[FlexibleSUSY`LowScaleInput, FlexibleSUSY`SUSYScaleInput, FlexibleSUSY`HighScaleInput],
                      FlexibleSUSY`FSSolveEWSBFor[___]],
                AppendTo[FlexibleSUSY`SUSYScaleInput,
                         FlexibleSUSY`FSSolveEWSBFor[FlexibleSUSY`EWSBOutputParameters]];
               ];
            ];
         ];

EnforceSLHA1Compliance[{parameter_, properties_List}] :=
    Module[{dims},
           dims = Select[properties, (First[#] === Parameters`ParameterDimensions)&];
           dims = Select[dims, And[Last[#] =!= {}, Last[#] =!= {0}, Last[#] =!= {1}]&];
           If[dims =!= {},
              Print["Error: the SLHA1 input parameter ", parameter, " must be a scalar!"];
              Print["   Please define ", parameter, " in a different block,"];
              Print["   or define it to be a scalar."];
              Quit[1];
             ];
          ];

AddSLHA1InputParameterInfo[parameter_, blockName_String, blockEntry_] :=
    Module[{i, definedPars, defaultInfo, oldInfo, pos, property},
           definedPars = First /@ FlexibleSUSY`FSAuxiliaryParameterInfo;
           defaultInfo = {parameter, { Parameters`ParameterDimensions -> {1},
                                       SARAH`LesHouches -> {blockName, blockEntry},
                                       Parameters`InputParameter -> True } };
           If[!MemberQ[definedPars, parameter],
              PrependTo[FlexibleSUSY`FSAuxiliaryParameterInfo, defaultInfo];,
              pos = Position[FlexibleSUSY`FSAuxiliaryParameterInfo, {parameter, {__}}];
              oldInfo = Extract[FlexibleSUSY`FSAuxiliaryParameterInfo, pos];
              EnforceSLHA1Compliance /@ oldInfo;
              For[i = 1, i <= Length[defaultInfo[[2]]], i++,
                  property = defaultInfo[[2,i]];
                  oldInfo = {#[[1]], Utils`AppendOrReplaceInList[#[[2]], property, (First[#1] === First[#2])&]}& /@ oldInfo;
                 ];
              FlexibleSUSY`FSAuxiliaryParameterInfo = ReplacePart[FlexibleSUSY`FSAuxiliaryParameterInfo,
                                                                  MapThread[Rule, {pos, oldInfo}]];
             ];
          ];

AddSLHA1InputBlockInfo[blockName_String, inputParameters_List] :=
    AddSLHA1InputParameterInfo[#[[2]], blockName, #[[1]]]& /@ inputParameters;

AddUnfixedParameterInfo[par_, inputPar_, blockList_] :=
    Module[{definedPars, outputBlock, inputBlock, info},
           definedPars = First /@ FlexibleSUSY`FSAuxiliaryParameterInfo;
           If[!MemberQ[definedPars, inputPar],
              outputBlock = Parameters`FindSLHABlock[blockList, par];
              inputBlock = WriteOut`CreateInputBlockName[outputBlock];
              info = {inputPar, { Parameters`InputParameter -> True,
                                  SARAH`LesHouches -> inputBlock,
                                  Parameters`ParameterDimensions -> Parameters`GetParameterDimensions[par],
                                  Parameters`MassDimension -> Parameters`GetModelParameterMassDimension[par]
                                } };
              AppendTo[FlexibleSUSY`FSAuxiliaryParameterInfo, info];
             ];
          ];

AddUnfixedParameterBlockInfo[unfixedParameters_List, blockList_List] :=
    AddUnfixedParameterInfo[#[[1]], #[[2]], blockList]& /@ unfixedParameters

FindFixedParameters[] :=
    If[FlexibleSUSY`FlexibleEFTHiggs === True,
       Join[Constraint`FindFixedParametersFromConstraint[FlexibleSUSY`SUSYScaleInput],
            Constraint`FindFixedParametersFromConstraint[FlexibleSUSY`HighScaleInput],
            Constraint`FindFixedParametersFromConstraint[FlexibleSUSY`SUSYScaleMatching],
            {SARAH`hyperchargeCoupling, SARAH`leftCoupling, SARAH`strongCoupling,
             SARAH`UpYukawa, SARAH`DownYukawa, SARAH`ElectronYukawa}]
       ,
       Join[Constraint`FindFixedParametersFromConstraint[FlexibleSUSY`LowScaleInput],
            Constraint`FindFixedParametersFromConstraint[FlexibleSUSY`SUSYScaleInput],
            Constraint`FindFixedParametersFromConstraint[FlexibleSUSY`HighScaleInput]]
      ];

FindUnfixedParameters[parameters_List, fixed_List] :=
    Complement[parameters, DeleteDuplicates[Flatten[fixed]]];

AddLesHouchesInputParameterInfo[par_, inputPar_, blockList_List] :=
    Module[{definedPars, outputBlock, inputBlock, info},
           definedPars = First /@ FlexibleSUSY`FSAuxiliaryParameterInfo;
           If[!MemberQ[definedPars, inputPar],
              outputBlock = Parameters`FindSLHABlock[blockList, par];
              inputBlock = WriteOut`CreateInputBlockName[outputBlock];
              info = {inputPar, { Parameters`InputParameter -> True,
                                  SARAH`LesHouches -> inputBlock,
                                  Parameters`ParameterDimensions -> Parameters`GetParameterDimensions[par],
                                  Parameters`MassDimension -> Parameters`GetModelParameterMassDimension[par]
                                } };
              AppendTo[FlexibleSUSY`FSAuxiliaryParameterInfo, info];
             ];
          ];

AddLesHouchesInputParameterBlockInfo[inputPars_List, blockList_List] :=
    AddLesHouchesInputParameterInfo[#[[1]], #[[2]], blockList]& /@ inputPars;

AppendLesHouchesInfo[lesHouchesList_List, auxiliaryInfo_List] :=
    Module[{getSLHAInfo},
           getSLHAInfo[{parameter_, properties_List}] :=
               Module[{block},
                      block = Cases[properties, (SARAH`LesHouches -> value_) :> value];
                      If[block === {},
                         block = None,
                         block = Last[block]
                        ];
                      {parameter, block}
                     ];
           Join[lesHouchesList, getSLHAInfo /@ auxiliaryInfo]
          ];

(* returns beta functions of VEV phases *)
GetVEVPhases[eigenstates_:FlexibleSUSY`FSEigenstates] :=
    Flatten @ Cases[DEFINITION[eigenstates][SARAH`VEVs], {_,_,_,_, p_} :> p];

AddSM3LoopRGE[beta_List, couplings_List] :=
    Module[{rules, MakeRule},
           MakeRule[coupling_] := {
               RuleDelayed[{coupling         , b1_, b2_}, {coupling       , b1, b2, Last[ThreeLoopSM`BetaSM[coupling]]}],
               RuleDelayed[{coupling[i1_,i2_], b1_, b2_}, {coupling[i1,i2], b1, b2, Last[ThreeLoopSM`BetaSM[coupling]] CConversion`PROJECTOR}]
           };
           rules = Flatten[MakeRule /@ couplings];
           beta /. rules
          ];

AddSM3LoopRGEs[] := Module[{
    gauge = { SARAH`hyperchargeCoupling,
              SARAH`leftCoupling,
              SARAH`strongCoupling },
    yuks  = { SARAH`UpYukawa,
              SARAH`DownYukawa,
              SARAH`ElectronYukawa },
    quart = { Parameters`GetParameterFromDescription["SM Higgs Selfcouplings"] },
    bilin = { Parameters`GetParameterFromDescription["SM Mu Parameter"] }
    },
    SARAH`BetaGauge = AddSM3LoopRGE[SARAH`BetaGauge, gauge];
    SARAH`BetaYijk  = AddSM3LoopRGE[SARAH`BetaYijk , yuks];
    SARAH`BetaLijkl = AddSM3LoopRGE[SARAH`BetaLijkl, quart];
    SARAH`BetaBij   = AddSM3LoopRGE[SARAH`BetaBij  , bilin];
    ];

AddMSSM3LoopRGE[beta_List, couplings_List] :=
    Module[{rules, MakeRule},
           MakeRule[coupling_] := {
               RuleDelayed[{coupling         , b1_, b2_}, {coupling       , b1, b2, Last[ThreeLoopMSSM`BetaMSSM[coupling]]}],
               RuleDelayed[{coupling[i1_,i2_], b1_, b2_}, {coupling[i1,i2], b1, b2, Last[ThreeLoopMSSM`BetaMSSM[coupling]]}]
           };
           rules = Flatten[MakeRule /@ couplings];
           beta /. rules
          ];

AddMSSM3LoopRGEs[] := Module[{
    gauge = { SARAH`hyperchargeCoupling,
              SARAH`leftCoupling,
              SARAH`strongCoupling },
    yuks  = { SARAH`UpYukawa,
              SARAH`DownYukawa,
              SARAH`ElectronYukawa },
    gaugi = { Parameters`GetParameterFromDescription["Bino Mass parameter"],
              Parameters`GetParameterFromDescription["Wino Mass parameter"],
              Parameters`GetParameterFromDescription["Gluino Mass parameter"] },
    trili = { SARAH`TrilinearUp, SARAH`TrilinearDown, SARAH`TrilinearLepton },
    mass2 = { SARAH`SoftSquark, SARAH`SoftUp, SARAH`SoftDown,
              SARAH`SoftLeftLepton, SARAH`SoftRightLepton,
              Parameters`GetParameterFromDescription["Softbreaking Down-Higgs Mass"],
              Parameters`GetParameterFromDescription["Softbreaking Up-Higgs Mass"] },
    mu    = { Parameters`GetParameterFromDescription["Mu-parameter"] },
    bmu   = { Parameters`GetParameterFromDescription["Bmu-parameter"] }
    },
    SARAH`BetaGauge = AddMSSM3LoopRGE[SARAH`BetaGauge, gauge];
    SARAH`BetaYijk  = AddMSSM3LoopRGE[SARAH`BetaYijk , yuks];
    SARAH`BetaMi    = AddMSSM3LoopRGE[SARAH`BetaMi   , gaugi];
    SARAH`BetaMuij  = AddMSSM3LoopRGE[SARAH`BetaMuij , mu   ];
    SARAH`BetaBij   = AddMSSM3LoopRGE[SARAH`BetaBij  , bmu  ];
    SARAH`BetaTijk  = AddMSSM3LoopRGE[SARAH`BetaTijk , trili];
    SARAH`Betam2ij  = AddMSSM3LoopRGE[SARAH`Betam2ij , mass2];
    ];

SelectRenormalizationScheme::UnknownRenormalizationScheme = "Unknown\
 renormalization scheme `1`.";

SelectRenormalizationScheme[renormalizationScheme_] :=
    Switch[renormalizationScheme,
           FlexibleSUSY`DRbar, 0,
           FlexibleSUSY`MSbar, 1,
           _, Message[SelectRenormalizationScheme::UnknownRenormalizationScheme, renormalizationScheme];
              Quit[1];
          ];

RenameSLHAInputParametersInUserInput[lesHouchesInputParameters_] :=
    Module[{lesHouchesInputParameterReplacementRules},
           lesHouchesInputParameterReplacementRules = Flatten[{
               Rule[SARAH`LHInput[#[[1]]], #[[2]]],
               Rule[SARAH`LHInput[#[[1]][p__]], #[[2]][p]]
           }& /@ lesHouchesInputParameters];

           FlexibleSUSY`LowScaleInput = FlexibleSUSY`LowScaleInput /.
               lesHouchesInputParameterReplacementRules;
           FlexibleSUSY`SUSYScaleInput = FlexibleSUSY`SUSYScaleInput /.
               lesHouchesInputParameterReplacementRules;
           FlexibleSUSY`HighScaleInput = FlexibleSUSY`HighScaleInput /.
               lesHouchesInputParameterReplacementRules;

           FlexibleSUSY`InitialGuessAtLowScale = FlexibleSUSY`InitialGuessAtLowScale /.
               lesHouchesInputParameterReplacementRules;
           FlexibleSUSY`InitialGuessAtSUSYScale = FlexibleSUSY`InitialGuessAtSUSYScale /.
               lesHouchesInputParameterReplacementRules;
           FlexibleSUSY`InitialGuessAtHighScale = FlexibleSUSY`InitialGuessAtHighScale /.
               lesHouchesInputParameterReplacementRules;

           FlexibleSUSY`LowScaleFirstGuess = FlexibleSUSY`LowScaleFirstGuess /.
               lesHouchesInputParameterReplacementRules;
           FlexibleSUSY`SUSYScaleFirstGuess = FlexibleSUSY`SUSYScaleFirstGuess /.
               lesHouchesInputParameterReplacementRules;
           FlexibleSUSY`HighScaleFirstGuess = FlexibleSUSY`HighScaleFirstGuess /.
               lesHouchesInputParameterReplacementRules;
          ];

Options[MakeFlexibleSUSY] :=
    {
        InputFile -> "FlexibleSUSY.m",
        OutputDirectory -> "",
        DebugOutput -> False
    };

MakeFlexibleSUSY[OptionsPattern[]] :=
    Module[{nPointFunctions, runInputFile, initialGuesserInputFile,
            gmm2Vertices = {},
            susyBetaFunctions, susyBreakingBetaFunctions,
            numberOfSusyParameters, anomDim,
            inputParameters (* list of 3-component lists of the form {name, block, type} *),
            massMatrices, phases,
            diagonalizationPrecision,
            allIntermediateOutputParameters = {},
            allIntermediateOutputParameterIndexReplacementRules = {},
            allInputParameterIndexReplacementRules = {},
            allExtraParameterIndexReplacementRules = {},
            allParticles, allParameters,
            ewsbEquations, sharedEwsbSubstitutions = {}, solverEwsbSubstitutions = {},
            freePhases = {}, solverFreePhases = {}, solverEwsbSolutions = {}, missingPhases,
            treeLevelEwsbSolutionOutputFiles = {}, treeLevelEwsbEqsOutputFile,
            solverEwsbSolvers = {}, fixedParameters,
            lesHouchesInputParameters,
            extraSLHAOutputBlocks, effectiveCouplings = {}, extraVertices = {},
            vertexRules, vertexRuleFileName, effectiveCouplingsFileName,
            Lat$massMatrices, spectrumGeneratorFiles = {}, spectrumGeneratorInputFile,
            semiAnalyticBCs, semiAnalyticSolns, semiAnalyticScale,
            semiAnalyticScaleInput, semiAnalyticScaleGuess,
            semiAnalyticScaleMinimum, semiAnalyticScaleMaximum,
            semiAnalyticSolnsOutputFile, semiAnalyticEWSBSubstitutions = {}, semiAnalyticInputScale = ""},

           PrintHeadline["Starting FlexibleSUSY"];
           FSDebugOutput["meta code directory: ", $flexiblesusyMetaDir];
           FSDebugOutput["config directory   : ", $flexiblesusyConfigDir];
           FSDebugOutput["templates directory: ", $flexiblesusyTemplateDir];

           (* check if SARAH`Start[] was called *)
           If[!ValueQ[Model`Name],
              Print["Error: Model`Name is not defined.  Did you call SARAH`Start[\"Model\"]?"];
              Quit[1];
             ];
           FSDebugOutput = OptionValue[DebugOutput];
           FSOutputDir = OptionValue[OutputDirectory];
           If[!DirectoryQ[FSOutputDir],
              Print["Error: OutputDirectory ", FSOutputDir, " does not exist."];
              Print["   Please run ./createmodel first."];
              Quit[1]];
           CheckSARAHVersion[];
           (* load model file *)
           LoadModelFile[OptionValue[InputFile]];
           Print["FlexibleSUSY model file loaded"];
           Print["  Model: ", Style[FlexibleSUSY`FSModelName, FSColor]];
           Print["  Model file: ", OptionValue[InputFile]];
           Print["  Model output directory: ", FSOutputDir];

           PrintHeadline["Reading SARAH output files"];
           (* get RGEs *)
           FSPrepareRGEs[FlexibleSUSY`FSRGELoopOrder];
           FSCheckLoopCorrections[FSEigenstates];
           nPointFunctions = EnforceCpColorStructures @ StripInvalidFieldIndices @
             Join[PrepareSelfEnergies[FSEigenstates], PrepareTadpoles[FSEigenstates]];
           (* GMM2 vertices *)
           gmm2Vertices = StripInvalidFieldIndices @ PrepareGMuonMinus2[];
           PrepareUnrotatedParticles[FSEigenstates];

           DebugPrint["particles (mass eigenstates): ", TreeMasses`GetParticles[]];

           FlexibleSUSY`FSRenormalizationScheme = GetRenormalizationScheme[];

           (* adapt SARAH`Conj to our needs *)
           (* Clear[Conj]; *)
           SARAH`Conj[(B_)[b__]] = .;
           SARAH`Conj /: SARAH`Conj[SARAH`Conj[x_]] := x;
           RXi[_] = 1;
           SARAH`Xi = 1;
           SARAH`Xip = 1;
           SARAH`rMS = SelectRenormalizationScheme[FlexibleSUSY`FSRenormalizationScheme];

           If[FlexibleSUSY`UseSM3LoopRGEs,
              Print["Adding SM 3-loop beta-functions from ",
                    "[arxiv:1303.4364v2, arXiv:1307.3536v4,",
                    " arXiv:1504.05200 (SUSYHD v1.0.1)]"];
              AddSM3LoopRGEs[];
             ];

           If[FlexibleSUSY`UseMSSM3LoopRGEs,
              Print["Adding MSSM 3-loop beta-functions from ",
                    "[arxiv:hep-ph/0308231, arxiv:hep-ph/0408128]"];
              AddMSSM3LoopRGEs[];
             ];

           If[SARAH`SupersymmetricModel,
              (* pick beta functions of supersymmetric parameters *)
              susyBetaFunctions = { SARAH`BetaLijkl,
                                    SARAH`BetaWijkl,
                                    SARAH`BetaYijk ,
                                    SARAH`BetaMuij ,
                                    SARAH`BetaLi   ,
                                    SARAH`BetaGauge,
                                    SARAH`BetaVEV  };

              (* pick beta functions of non-supersymmetric parameters *)
              susyBreakingBetaFunctions = { SARAH`BetaQijkl,
                                            SARAH`BetaTijk ,
                                            SARAH`BetaBij  ,
                                            SARAH`BetaLSi  ,
                                            SARAH`Betam2ij ,
                                            SARAH`BetaMi   ,
                                            SARAH`BetaDGi  };
              ,
              (* pick beta functions of dimensionless parameters *)
              susyBetaFunctions = { SARAH`BetaGauge,
                                    SARAH`BetaLijkl, (* quartic scalar interactions *)
                                    SARAH`BetaYijk };

              (* pick beta functions of dimensionfull parameters *)
              susyBreakingBetaFunctions = { SARAH`BetaTijk, (* cubic scalar interactions *)
                                            SARAH`BetaMuij, (* bilinear fermion term *)
                                            SARAH`BetaBij , (* bilinear scalar term *)
                                            SARAH`BetaLi  , (* linear scalar term *)
                                            SARAH`BetaVEV };
             ];

           (* filter out buggy and duplicate beta functions *)
           DeleteBuggyBetaFunctions[beta_List] :=
               DeleteDuplicates[Select[beta, (!NumericQ[#[[1]]])&], (#1[[1]] === #2[[1]])&];
           susyBetaFunctions         = DeleteBuggyBetaFunctions /@ susyBetaFunctions;
           susyBreakingBetaFunctions = DeleteBuggyBetaFunctions /@ susyBreakingBetaFunctions;

           (* identify real parameters *)
           If[Head[SARAH`RealParameters] === List,
              Parameters`AddRealParameter[SARAH`RealParameters];
             ];

           (* store all model parameters *)
           allParameters = StripSARAHIndices[((#[[1]])& /@ Join[Join @@ susyBetaFunctions, Join @@ susyBreakingBetaFunctions])];
           Parameters`SetModelParameters[allParameters];
           DebugPrint["model parameters: ", allParameters];

           anomDim = AnomalousDimension`ConvertSarahAnomDim[SARAH`Gij];

           susyBetaFunctions = BetaFunction`ConvertSarahRGEs[susyBetaFunctions];
           susyBetaFunctions = Select[susyBetaFunctions, (BetaFunction`GetAllBetaFunctions[#]!={})&];

           susyBreakingBetaFunctions = ConvertSarahRGEs[susyBreakingBetaFunctions];
           susyBreakingBetaFunctions = Select[susyBreakingBetaFunctions, (BetaFunction`GetAllBetaFunctions[#]!={})&];

           allBetaFunctions = Join[susyBetaFunctions, susyBreakingBetaFunctions];

           numberOfSusyParameters = BetaFunction`CountNumberOfParameters[susyBetaFunctions];
           numberOfSusyBreakingParameters = BetaFunction`CountNumberOfParameters[susyBreakingBetaFunctions];
           numberOfModelParameters = numberOfSusyParameters + numberOfSusyBreakingParameters;

           (* collect all phases from SARAH *)
           phases = DeleteDuplicates @ Join[
               ConvertSarahPhases[SARAH`ParticlePhases],
               Exp[I #]& /@ GetVEVPhases[FlexibleSUSY`FSEigenstates]];
           Parameters`SetPhases[phases];

           FlexibleSUSY`FSLesHouchesList = SA`LHList;

           (* collect input parameters from MINPAR and EXTPAR lists *)
           AddSLHA1InputBlockInfo["IMEXTPAR", Reverse @ IMEXTPAR];
           AddSLHA1InputBlockInfo["IMMINPAR", Reverse @ IMMINPAR];
           AddSLHA1InputBlockInfo["EXTPAR", Reverse @ SARAH`EXTPAR];
           AddSLHA1InputBlockInfo["MINPAR", Reverse @ SARAH`MINPAR];

           (* search for unfixed parameters *)
           Constraint`SanityCheck[Join[If[FlexibleEFTHiggs === True,
                                          FlexibleSUSY`InitialGuessAtSUSYScale,
                                          FlexibleSUSY`InitialGuessAtLowScale],
                                       FlexibleSUSY`InitialGuessAtHighScale],
                                  "initial guess"
                                 ];

           (* add SM gauge couplings to low-scale constraint if not set anywhere *)
           EnsureSMGaugeCouplingsSet[];

           (* add EWSB constraint to SUSY-scale constraint if not set *)
           EnsureEWSBConstraintApplied[];

           fixedParameters = FindFixedParameters[];
           FlexibleSUSY`FSUnfixedParameters = FindUnfixedParameters[allParameters, fixedParameters];

           If[FlexibleSUSY`FSUnfixedParameters =!= {} &&
              FlexibleSUSY`AutomaticInputAtMSUSY =!= True,
              Print["Warning: the following parameters are not fixed by any constraint:"];
              Print["  ", FlexibleSUSY`FSUnfixedParameters];
             ];

           (* add the unfixed parameters to the susy scale constraint *)
           If[FlexibleSUSY`OnlyLowEnergyFlexibleSUSY === True &&
              FlexibleSUSY`AutomaticInputAtMSUSY,
              (* adding input names for the parameters *)
              FlexibleSUSY`FSUnfixedParameters = Select[StripSARAHIndices[Join[{BetaFunction`GetName[#], Symbol[CConversion`ToValidCSymbolString[BetaFunction`GetName[#]] <> "Input"]}& /@ susyBetaFunctions,
                                                                               {BetaFunction`GetName[#], Symbol[CConversion`ToValidCSymbolString[BetaFunction`GetName[#]] <> "Input"]}& /@ susyBreakingBetaFunctions]],
                                                        MemberQ[FlexibleSUSY`FSUnfixedParameters,#[[1]]]&];
              FlexibleSUSY`SUSYScaleInput = Join[FlexibleSUSY`SUSYScaleInput,
                                                 {#[[1]],#[[2]]}& /@ FlexibleSUSY`FSUnfixedParameters];
              AddUnfixedParameterBlockInfo[FlexibleSUSY`FSUnfixedParameters, FlexibleSUSY`FSLesHouchesList];
             ];

           lesHouchesInputParameters = DeleteDuplicates[
               Flatten[
                   Cases[
                       Join[FlexibleSUSY`LowScaleInput,
                            FlexibleSUSY`SUSYScaleInput,
                            FlexibleSUSY`HighScaleInput,
                            FlexibleSUSY`InitialGuessAtLowScale,
                            FlexibleSUSY`InitialGuessAtHighScale,
                            {FlexibleSUSY`LowScaleFirstGuess,
                             FlexibleSUSY`SUSYScaleFirstGuess,
                             FlexibleSUSY`HighScaleFirstGuess}
                           ],
                       SARAH`LHInput[p_] :> Parameters`StripIndices[p],
                       Infinity
                        ]
                      ]
           ];

           lesHouchesInputParameters = Select[StripSARAHIndices[{BetaFunction`GetName[#],
                                                                 Symbol[CConversion`ToValidCSymbolString[BetaFunction`GetName[#]] <> "Input"]
                                                                }& /@ Join[susyBetaFunctions, susyBreakingBetaFunctions]],
                                              MemberQ[lesHouchesInputParameters,#[[1]]]&];

           AddLesHouchesInputParameterBlockInfo[lesHouchesInputParameters, FlexibleSUSY`FSLesHouchesList];

           (* apply parameter definitions and properties *)
           Parameters`ApplyAuxiliaryParameterInfo[FlexibleSUSY`FSAuxiliaryParameterInfo];
           Parameters`CheckInputParameterDefinitions[];

           FlexibleSUSY`FSLesHouchesList = AppendLesHouchesInfo[FlexibleSUSY`FSLesHouchesList, FlexibleSUSY`FSAuxiliaryParameterInfo];

           inputParameters = Parameters`GetInputParametersAndTypes[];

           DebugPrint["input parameters: ", Parameters`GetInputParameters[]];
           DebugPrint["auxiliary parameters: ", Parameters`GetExtraParameters[]];

           allIndexReplacementRules = Join[
               Parameters`CreateIndexReplacementRules[allParameters],
               {Global`upQuarksDRbar[i_,j_] :> Global`upQuarksDRbar[i-1,j-1],
                Global`downQuarksDRbar[i_,j_] :> Global`downQuarksDRbar[i-1,j-1],
                Global`downLeptonsDRbar[i_,j_] :> Global`downLeptonsDRbar[i-1,j-1]}
           ];

           allInputParameterIndexReplacementRules = Parameters`CreateIndexReplacementRules[
               Parameters`GetInputParameters[]
            ];

           allExtraParameterIndexReplacementRules = Parameters`CreateIndexReplacementRules[
               Parameters`GetExtraParameters[]
            ];

           On[Assert];

           Lat$massMatrices = TreeMasses`ConvertSarahMassMatrices[] /.
                              Parameters`ApplyGUTNormalization[] //.
                              { SARAH`sum[j_, start_, end_, expr_] :> (Sum[expr, {j,start,end}]) };
           massMatrices = Lat$massMatrices /. allIndexReplacementRules;
           Lat$massMatrices = LatticeUtils`FixDiagonalization[Lat$massMatrices];

           allIntermediateOutputParameters =
               Parameters`GetIntermediateOutputParameterDependencies[TreeMasses`GetMassMatrix /@ massMatrices];
           DebugPrint["intermediate output parameters = ", allIntermediateOutputParameters];

           (* decrease index literals of intermediate output parameters in mass matrices *)
           allIntermediateOutputParameterIndexReplacementRules =
               Parameters`CreateIndexReplacementRules[allIntermediateOutputParameters];

           massMatrices = massMatrices /. allIntermediateOutputParameterIndexReplacementRules;

           allParticles = FlexibleSUSY`M[TreeMasses`GetMassEigenstate[#]]& /@ massMatrices;
           allOutputParameters = DeleteCases[DeleteDuplicates[
               Join[allParticles,
                    Flatten[TreeMasses`GetMixingMatrixSymbol[#]& /@ massMatrices]]], Null];

           Parameters`SetOutputParameters[allOutputParameters];
           DebugPrint["output parameters = ", allOutputParameters];

           (* backwards compatibility replacements in constraints *)
           backwardsCompatRules = {
               Global`topDRbar      -> Global`upQuarksDRbar,
               Global`bottomDRbar   -> Global`downQuarksDRbar,
               Global`electronDRbar -> Global`downLeptonsDRbar
           };
           FlexibleSUSY`LowScaleInput  = FlexibleSUSY`LowScaleInput  /. backwardsCompatRules;
           FlexibleSUSY`SUSYScaleInput = FlexibleSUSY`SUSYScaleInput /. backwardsCompatRules;
           FlexibleSUSY`HighScaleInput = FlexibleSUSY`HighScaleInput /. backwardsCompatRules;
           FlexibleSUSY`InitialGuessAtLowScale  = FlexibleSUSY`InitialGuessAtLowScale  /. backwardsCompatRules;
           FlexibleSUSY`InitialGuessAtHighScale = FlexibleSUSY`InitialGuessAtHighScale /. backwardsCompatRules;

           Constraint`CheckConstraint[FlexibleSUSY`LowScaleInput, "LowScaleInput"];
           Constraint`CheckConstraint[FlexibleSUSY`SUSYScaleInput, "SUSYScaleInput"];
           Constraint`CheckConstraint[FlexibleSUSY`HighScaleInput, "HighScaleInput"];
           Constraint`CheckConstraint[FlexibleSUSY`InitialGuessAtLowScale, "InitialGuessAtLowScale"];
           Constraint`CheckConstraint[FlexibleSUSY`InitialGuessAtSUSYScale, "InitialGuessAtSUSYScale"];
           Constraint`CheckConstraint[FlexibleSUSY`InitialGuessAtHighScale, "InitialGuessAtHighScale"];

           (* warn if extra parameters, which do not run, are used at multiple scales *)
           CheckExtraParametersUsage[Parameters`GetExtraParameters[],
                                     {FlexibleSUSY`LowScaleInput, FlexibleSUSY`SUSYScaleInput, FlexibleSUSY`HighScaleInput}];

           (* replace all indices in the user-defined model file variables *)
           EvaluateUserInput[];
           ReplaceIndicesInUserInput[allIndexReplacementRules];
           ReplaceIndicesInUserInput[allInputParameterIndexReplacementRules];
           ReplaceIndicesInUserInput[allExtraParameterIndexReplacementRules];

           (* replace LHInput[p] by pInput in the constraints *)
           RenameSLHAInputParametersInUserInput[lesHouchesInputParameters];

           If[HaveBVPSolver[FlexibleSUSY`SemiAnalyticSolver],
              SemiAnalytic`SetSemiAnalyticParameters[BetaFunction`GetName[#]& /@ susyBreakingBetaFunctions];

              (* @note currently require all semi-analytic parameters to be set at same scale *)
              If[!SemiAnalytic`CheckSemiAnalyticBoundaryConditions[{FlexibleSUSY`LowScaleInput,
                                                                    FlexibleSUSY`SUSYScaleInput,
                                                                    FlexibleSUSY`HighScaleInput}],
                 Print["Error: the requested boundary conditions are not"];
                 Print["   supported by the semi-analytic solver."];
                 Print["   Please modify the boundary conditions or disable"];
                 Print["   the semi-analytic solver."];
                 Print["   Alternatively, please contact the developers to"];
                 Print["   discuss adding support for these boundary conditions."];
                 Quit[1];
                ];

              semiAnalyticBCs = SemiAnalytic`SelectSemiAnalyticConstraint[{FlexibleSUSY`LowScaleInput,
                                                                           FlexibleSUSY`SUSYScaleInput,
                                                                           FlexibleSUSY`HighScaleInput}];

              semiAnalyticSolns = SemiAnalytic`GetSemiAnalyticSolutions[semiAnalyticBCs];
             ];

           PrintHeadline["Creating model parameter classes"];
           Print["Creating class for susy parameters ..."];
           WriteRGEClass[susyBetaFunctions, anomDim,
                         {{FileNameJoin[{$flexiblesusyTemplateDir, "susy_parameters.hpp.in"}],
                           FileNameJoin[{FSOutputDir, FlexibleSUSY`FSModelName <> "_susy_parameters.hpp"}]},
                          {FileNameJoin[{$flexiblesusyTemplateDir, "susy_parameters.cpp.in"}],
                           FileNameJoin[{FSOutputDir, FlexibleSUSY`FSModelName <> "_susy_parameters.cpp"}]}},
                         "susy_beta_.cpp.in",
                         {{FileNameJoin[{$flexiblesusyTemplateDir, "betas.mk.in"}],
                           FileNameJoin[{FSOutputDir, "susy_betas.mk"}]}}
                        ];

           Print["Creating class for soft parameters ..."];
           WriteRGEClass[susyBreakingBetaFunctions, {},
                         {{FileNameJoin[{$flexiblesusyTemplateDir, "soft_parameters.hpp.in"}],
                           FileNameJoin[{FSOutputDir, FlexibleSUSY`FSModelName <> "_soft_parameters.hpp"}]},
                          {FileNameJoin[{$flexiblesusyTemplateDir, "soft_parameters.cpp.in"}],
                           FileNameJoin[{FSOutputDir, FlexibleSUSY`FSModelName <> "_soft_parameters.cpp"}]}},
                         "soft_beta_.cpp.in",
                         {{FileNameJoin[{$flexiblesusyTemplateDir, "betas.mk.in"}],
                           FileNameJoin[{FSOutputDir, "soft_betas.mk"}]}},
                         If[Head[SARAH`TraceAbbr] === List, SARAH`TraceAbbr, {}],
                         numberOfSusyParameters];

           (********************* EWSB *********************)
           ewsbEquations = PrepareEWSBEquations[allIndexReplacementRules];

           If[FlexibleSUSY`EWSBInitialGuess =!= {},
              FlexibleSUSY`EWSBInitialGuess = EWSB`GetValidEWSBInitialGuesses[FlexibleSUSY`EWSBInitialGuess];
             ];

           If[FlexibleSUSY`EWSBSubstitutions =!= {},
              sharedEwsbSubstitutions = EWSB`GetValidEWSBSubstitutions[FlexibleSUSY`EWSBSubstitutions];
              sharedEwsbSubstitutions = (Rule @@ #)& /@ (sharedEwsbSubstitutions /. allIndexReplacementRules);
             ];
           solverEwsbSubstitutions = Rule[#, sharedEwsbSubstitutions]& /@ FlexibleSUSY`FSBVPSolvers;

           If[HaveBVPSolver[FlexibleSUSY`SemiAnalyticSolver],
              semiAnalyticEWSBSubstitutions = SemiAnalytic`GetSemiAnalyticEWSBSubstitutions[semiAnalyticSolns];
              solverEwsbSubstitutions = AddEWSBSubstitutionsForSolver[FlexibleSUSY`SemiAnalyticSolver,
                                                                      solverEwsbSubstitutions,
                                                                      semiAnalyticEWSBSubstitutions];
             ];

           FlexibleSUSY`EWSBOutputParameters = Parameters`DecreaseIndexLiterals[FlexibleSUSY`EWSBOutputParameters];
           If[ewsbEquations =!= {},
              treeLevelEwsbEqsOutputFile = FileNameJoin[{FSOutputDir, FlexibleSUSY`FSModelName <> "_EWSB_equations.m"}];
              Print["Writing EWSB equations to ", treeLevelEwsbEqsOutputFile];
              If[sharedEwsbSubstitutions =!= {},
                 Put[Parameters`ReplaceAllRespectingSARAHHeads[ewsbEquations, sharedEwsbSubstitutions], treeLevelEwsbEqsOutputFile],
                 Put[ewsbEquations, treeLevelEwsbEqsOutputFile]
                ];

              treeLevelEwsbSolutionOutputFiles =
                  (Rule[#, FileNameJoin[{FSOutputDir, FlexibleSUSY`FSModelName <> "_"
                                                      <> GetBVPSolverHeaderName[#] <> "_EWSB_solution.m"}]])& /@ FlexibleSUSY`FSBVPSolvers;
              {solverEwsbSolutions, solverFreePhases} = SolveEWSBEquationsForSolvers[FlexibleSUSY`FSBVPSolvers, ewsbEquations,
                                                                                     FlexibleSUSY`EWSBOutputParameters, solverEwsbSubstitutions,
                                                                                     FlexibleSUSY`TreeLevelEWSBSolution,
                                                                                     treeLevelEwsbSolutionOutputFiles];
              ,
              Print["Note: There are no EWSB equations."];
              solverEwsbSolutions = Rule[#, {}]& /@ FlexibleSUSY`FSBVPSolvers;
              solverFreePhases = Rule[#, {}]& /@ FlexibleSUSY`FSBVPSolvers;
             ];
           freePhases = GetAllFreePhases[solverFreePhases];
           If[freePhases =!= {},
              Print["Note: the following phases are free: ", freePhases];
              missingPhases = Select[freePhases, !MemberQ[#[[1]]& /@ inputParameters, #]&];
              If[missingPhases =!= {},
                 Print["Error: the following phases are not defined as input parameters: ", InputForm[missingPhases]];
                 Print["   Please add them to the MINPAR or EXTPAR input parameter lists."];
                 Quit[1];
                ];
             ];

           If[Cases[solverEwsbSolutions, (Rule[solver_, {}]) :> solver] =!= {},
              Print["Warning: an analytic solution to the EWSB eqs. ",
                    " could not be found for the solvers: ",
                    Cases[solverEwsbSolutions, (Rule[solver_ , {}]) :> solver]];
              Print["   An iterative algorithm will be used.  You can try to set"];
              Print["   the solution by hand in the model file like this:"];
              Print[""];
              Print["   TreeLevelEWSBSolution = {"];
              For[i = 1, i <= Length[FlexibleSUSY`EWSBOutputParameters], i++,
              Print["      { ", FlexibleSUSY`EWSBOutputParameters[[i]], ", ... }" <>
                    If[i != Length[FlexibleSUSY`EWSBOutputParameters], ",", ""]];
                   ];
              Print["   };\n"];
             ];
           solverEwsbSolvers = SelectValidEWSBSolvers[solverEwsbSolutions, FlexibleSUSY`FSEWSBSolvers];

           Print["Input parameters: ", InputForm[Parameters`GetInputParameters[]]];

           Print["Creating class for input parameters ..."];
           WriteInputParameterClass[inputParameters,
                                    {{FileNameJoin[{$flexiblesusyTemplateDir, "input_parameters.hpp.in"}],
                                      FileNameJoin[{FSOutputDir, FlexibleSUSY`FSModelName <> "_input_parameters.hpp"}]},
                                     {FileNameJoin[{$flexiblesusyTemplateDir, "input_parameters.cpp.in"}],
                                      FileNameJoin[{FSOutputDir, FlexibleSUSY`FSModelName <> "_input_parameters.cpp"}]}
                                    }
                                   ];

           extraSLHAOutputBlocks = Parameters`DecreaseIndexLiterals[
               FlexibleSUSY`ExtraSLHAOutputBlocks,
               Join[Parameters`GetOutputParameters[], Parameters`GetModelParameters[]]
           ];

           (* check weak mixing angle parameters *)
           FlexibleSUSY`FSWeakMixingAngleOptions =
               Utils`FSSetOption[FlexibleSUSY`FSWeakMixingAngleOptions,
                                 FlexibleSUSY`FSWeakMixingAngleInput ->
                                 CheckWeakMixingAngleInputRequirements[Utils`FSGetOption[
                                     FlexibleSUSY`FSWeakMixingAngleOptions,
                                     FlexibleSUSY`FSWeakMixingAngleInput]
                                 ]
               ];

           (* determine diagonalization precision for each particle *)
           diagonalizationPrecision = ReadPoleMassPrecisions[
               DefaultPoleMassPrecision,
               Flatten[{HighPoleMassPrecision}],
               Flatten[{MediumPoleMassPrecision}],
               Flatten[{LowPoleMassPrecision}],
               FSEigenstates];

           vertexRuleFileName =
              GetVertexRuleFileName[$sarahCurrentOutputMainDir, FSEigenstates];
           effectiveCouplingsFileName =
              GetEffectiveCouplingsFileName[$sarahCurrentOutputMainDir, FSEigenstates];
           If[NeedToCalculateVertices[FSEigenstates],
              (* effectiveCouplings = {{coupling, {needed couplings}}, ...} *)
              Put[effectiveCouplings =
                      EffectiveCouplings`InitializeEffectiveCouplings[],
                  effectiveCouplingsFileName];
              extraVertices = EffectiveCouplings`GetNeededVerticesList[effectiveCouplings];
              Put[vertexRules =
                      Vertices`VertexRules[Join[nPointFunctions, gmm2Vertices, extraVertices], Lat$massMatrices],
                  vertexRuleFileName],
              vertexRules = Get[vertexRuleFileName];
              effectiveCouplings = Get[effectiveCouplingsFileName];
             ];

           PrintHeadline["Creating model"];
           Print["Creating class for model ..."];
           WriteModelClass[massMatrices, ewsbEquations, FlexibleSUSY`EWSBOutputParameters,
                           DeleteDuplicates[Flatten[#[[2]]& /@ solverEwsbSubstitutions]], nPointFunctions, vertexRules, Parameters`GetPhases[],
                           {{FileNameJoin[{$flexiblesusyTemplateDir, "mass_eigenstates.hpp.in"}],
                             FileNameJoin[{FSOutputDir, FlexibleSUSY`FSModelName <> "_mass_eigenstates.hpp"}]},
                            {FileNameJoin[{$flexiblesusyTemplateDir, "mass_eigenstates.cpp.in"}],
                             FileNameJoin[{FSOutputDir, FlexibleSUSY`FSModelName <> "_mass_eigenstates.cpp"}]},
                            {FileNameJoin[{$flexiblesusyTemplateDir, "physical.hpp.in"}],
                             FileNameJoin[{FSOutputDir, FlexibleSUSY`FSModelName <> "_physical.hpp"}]},
                            {FileNameJoin[{$flexiblesusyTemplateDir, "physical.cpp.in"}],
                             FileNameJoin[{FSOutputDir, FlexibleSUSY`FSModelName <> "_physical.cpp"}]}
                           },
                           diagonalizationPrecision];

           PrintHeadline["Creating SLHA model"];
           Print["Creating class for SLHA model ..."];
           WriteModelSLHAClass[massMatrices,
                               {{FileNameJoin[{$flexiblesusyTemplateDir, "model_slha.hpp.in"}],
                                 FileNameJoin[{FSOutputDir, FlexibleSUSY`FSModelName <> "_model_slha.hpp"}]}
                               }];

           PrintHeadline["Creating utilities"];
           Print["Creating utilities class ..."];
           WriteUtilitiesClass[massMatrices, Join[susyBetaFunctions, susyBreakingBetaFunctions],
                               inputParameters, FlexibleSUSY`FSLesHouchesList, extraSLHAOutputBlocks,
               {{FileNameJoin[{$flexiblesusyTemplateDir, "info.hpp.in"}],
                 FileNameJoin[{FSOutputDir, FlexibleSUSY`FSModelName <> "_info.hpp"}]},
                {FileNameJoin[{$flexiblesusyTemplateDir, "info.cpp.in"}],
                 FileNameJoin[{FSOutputDir, FlexibleSUSY`FSModelName <> "_info.cpp"}]},
                {FileNameJoin[{$flexiblesusyTemplateDir, "utilities.hpp.in"}],
                 FileNameJoin[{FSOutputDir, FlexibleSUSY`FSModelName <> "_utilities.hpp"}]},
                {FileNameJoin[{$flexiblesusyTemplateDir, "utilities.cpp.in"}],
                 FileNameJoin[{FSOutputDir, FlexibleSUSY`FSModelName <> "_utilities.cpp"}]},
                {FileNameJoin[{$flexiblesusyTemplateDir, "slha_io.hpp.in"}],
                 FileNameJoin[{FSOutputDir, FlexibleSUSY`FSModelName <> "_slha_io.hpp"}]},
                {FileNameJoin[{$flexiblesusyTemplateDir, "slha_io.cpp.in"}],
                 FileNameJoin[{FSOutputDir, FlexibleSUSY`FSModelName <> "_slha_io.cpp"}]}
               }
                              ];

           Print["Creating FlexibleEFTHiggs.mk ..."];
           WriteFlexibleEFTHiggsMakefileModule[
                              {{FileNameJoin[{$flexiblesusyTemplateDir, "FlexibleEFTHiggs.mk.in"}],
                                FileNameJoin[{FSOutputDir, "FlexibleEFTHiggs.mk"}]}
                              }];

           If[FlexibleSUSY`FlexibleEFTHiggs === True,
              Print["Creating matching class ..."];
              WriteMatchingClass[FlexibleSUSY`SUSYScaleMatching, massMatrices,
                                 {{FileNameJoin[{$flexiblesusyTemplateDir, "standard_model_matching.hpp.in"}],
                                   FileNameJoin[{FSOutputDir, FlexibleSUSY`FSModelName <> "_standard_model_matching.hpp"}]},
                                  {FileNameJoin[{$flexiblesusyTemplateDir, "standard_model_matching.cpp.in"}],
                                   FileNameJoin[{FSOutputDir, FlexibleSUSY`FSModelName <> "_standard_model_matching.cpp"}]}
                                 }];
             ];

           Print["Creating plot scripts ..."];
           WritePlotScripts[{{FileNameJoin[{$flexiblesusyTemplateDir, "plot_spectrum.gnuplot.in"}],
                              FileNameJoin[{FSOutputDir, FlexibleSUSY`FSModelName <> "_plot_spectrum.gnuplot"}]},
                             {FileNameJoin[{$flexiblesusyTemplateDir, "plot_rgflow.gnuplot.in"}],
                              FileNameJoin[{FSOutputDir, FlexibleSUSY`FSModelName <> "_plot_rgflow.gnuplot"}]}}
                           ];

           PrintHeadline["Creating solver framework"];
           Print["Creating generic solver class templates ..."];
           WriteBVPSolverTemplates[{{FileNameJoin[{$flexiblesusyTemplateDir, "convergence_tester.hpp.in"}],
                                     FileNameJoin[{FSOutputDir, FlexibleSUSY`FSModelName <> "_convergence_tester.hpp"}]},
                                    {FileNameJoin[{$flexiblesusyTemplateDir, "ewsb_solver.hpp.in"}],
                                     FileNameJoin[{FSOutputDir, FlexibleSUSY`FSModelName <> "_ewsb_solver.hpp"}]},
                                    {FileNameJoin[{$flexiblesusyTemplateDir, "ewsb_solver_interface.hpp.in"}],
                                     FileNameJoin[{FSOutputDir, FlexibleSUSY`FSModelName <> "_ewsb_solver_interface.hpp"}]},
                                    {FileNameJoin[{$flexiblesusyTemplateDir, "high_scale_constraint.hpp.in"}],
                                     FileNameJoin[{FSOutputDir, FlexibleSUSY`FSModelName <> "_high_scale_constraint.hpp"}]},
                                    {FileNameJoin[{$flexiblesusyTemplateDir, "initial_guesser.hpp.in"}],
                                     FileNameJoin[{FSOutputDir, FlexibleSUSY`FSModelName <> "_initial_guesser.hpp"}]},
                                    {FileNameJoin[{$flexiblesusyTemplateDir, "low_scale_constraint.hpp.in"}],
                                     FileNameJoin[{FSOutputDir, FlexibleSUSY`FSModelName <> "_low_scale_constraint.hpp"}]},
                                    {FileNameJoin[{$flexiblesusyTemplateDir, "model.hpp.in"}],
                                     FileNameJoin[{FSOutputDir, FlexibleSUSY`FSModelName <> "_model.hpp"}]},
                                    {FileNameJoin[{$flexiblesusyTemplateDir, "spectrum_generator.hpp.in"}],
                                     FileNameJoin[{FSOutputDir, FlexibleSUSY`FSModelName <> "_spectrum_generator.hpp"}]},
                                    {FileNameJoin[{$flexiblesusyTemplateDir, "spectrum_generator_interface.hpp.in"}],
                                     FileNameJoin[{FSOutputDir, FlexibleSUSY`FSModelName <> "_spectrum_generator_interface.hpp"}]},
                                    {FileNameJoin[{$flexiblesusyTemplateDir, "susy_scale_constraint.hpp.in"}],
                                     FileNameJoin[{FSOutputDir, FlexibleSUSY`FSModelName <> "_susy_scale_constraint.hpp"}]}
                                   }];

           If[HaveBVPSolver[FlexibleSUSY`TwoScaleSolver],
              PrintHeadline["Creating two-scale solver"];
              Print["Creating class for convergence tester ..."];
              WriteConvergenceTesterClass[FlexibleSUSY`FSConvergenceCheck,
                  {{FileNameJoin[{$flexiblesusyTemplateDir, "two_scale_convergence_tester.hpp.in"}],
                    FileNameJoin[{FSOutputDir, FlexibleSUSY`FSModelName <> "_two_scale_convergence_tester.hpp"}]},
                   {FileNameJoin[{$flexiblesusyTemplateDir, "two_scale_convergence_tester.cpp.in"}],
                    FileNameJoin[{FSOutputDir, FlexibleSUSY`FSModelName <> "_two_scale_convergence_tester.cpp"}]}
                  }
                                         ];

              Print["Creating class for high-scale constraint ..."];
              WriteConstraintClass[FlexibleSUSY`HighScale,
                                   FlexibleSUSY`HighScaleInput,
                                   FlexibleSUSY`HighScaleFirstGuess,
                                   {FlexibleSUSY`HighScaleMinimum, FlexibleSUSY`HighScaleMaximum},
                                   {{FileNameJoin[{$flexiblesusyTemplateDir, "two_scale_high_scale_constraint.hpp.in"}],
                                     FileNameJoin[{FSOutputDir, FlexibleSUSY`FSModelName <> "_two_scale_high_scale_constraint.hpp"}]},
                                    {FileNameJoin[{$flexiblesusyTemplateDir, "two_scale_high_scale_constraint.cpp.in"}],
                                     FileNameJoin[{FSOutputDir, FlexibleSUSY`FSModelName <> "_two_scale_high_scale_constraint.cpp"}]}
                                   }
                                  ];

              Print["Creating class for susy-scale constraint ..."];
              WriteConstraintClass[FlexibleSUSY`SUSYScale,
                                   FlexibleSUSY`SUSYScaleInput,
                                   FlexibleSUSY`SUSYScaleFirstGuess,
                                   {FlexibleSUSY`SUSYScaleMinimum, FlexibleSUSY`SUSYScaleMaximum},
                                   {{FileNameJoin[{$flexiblesusyTemplateDir, "two_scale_susy_scale_constraint.hpp.in"}],
                                     FileNameJoin[{FSOutputDir, FlexibleSUSY`FSModelName <> "_two_scale_susy_scale_constraint.hpp"}]},
                                    {FileNameJoin[{$flexiblesusyTemplateDir, "two_scale_susy_scale_constraint.cpp.in"}],
                                     FileNameJoin[{FSOutputDir, FlexibleSUSY`FSModelName <> "_two_scale_susy_scale_constraint.cpp"}]}
                                   }
                                  ];

              Print["Creating class for low-scale constraint ..."];
              WriteConstraintClass[FlexibleSUSY`LowScale,
                                   FlexibleSUSY`LowScaleInput,
                                   FlexibleSUSY`LowScaleFirstGuess,
                                   {FlexibleSUSY`LowScaleMinimum, FlexibleSUSY`LowScaleMaximum},
                                   {{FileNameJoin[{$flexiblesusyTemplateDir, "two_scale_low_scale_constraint.hpp.in"}],
                                     FileNameJoin[{FSOutputDir, FlexibleSUSY`FSModelName <> "_two_scale_low_scale_constraint.hpp"}]},
                                    {FileNameJoin[{$flexiblesusyTemplateDir, "two_scale_low_scale_constraint.cpp.in"}],
                                     FileNameJoin[{FSOutputDir, FlexibleSUSY`FSModelName <> "_two_scale_low_scale_constraint.cpp"}]}
                                   }
                                  ];

              Print["Creating class for initial guesser ..."];
              If[FlexibleSUSY`OnlyLowEnergyFlexibleSUSY,
                 initialGuesserInputFile = "two_scale_low_scale_initial_guesser";,
                 initialGuesserInputFile = "two_scale_high_scale_initial_guesser";
                ];
              If[FlexibleSUSY`FlexibleEFTHiggs === True,
                 initialGuesserInputFile = "standard_model_" <> initialGuesserInputFile;
                ];
              WriteInitialGuesserClass[FlexibleSUSY`InitialGuessAtLowScale,
                                       FlexibleSUSY`InitialGuessAtSUSYScale,
                                       FlexibleSUSY`InitialGuessAtHighScale,
                                       {{FileNameJoin[{$flexiblesusyTemplateDir, initialGuesserInputFile <> ".hpp.in"}],
                                         FileNameJoin[{FSOutputDir, FlexibleSUSY`FSModelName <> "_two_scale_initial_guesser.hpp"}]},
                                        {FileNameJoin[{$flexiblesusyTemplateDir, initialGuesserInputFile <> ".cpp.in"}],
                                         FileNameJoin[{FSOutputDir, FlexibleSUSY`FSModelName <> "_two_scale_initial_guesser.cpp"}]}
                                       }
                                      ];

              Print["Creating class for two-scale EWSB solver ..."];
              WriteEWSBSolverClass[ewsbEquations, FlexibleSUSY`EWSBOutputParameters, FlexibleSUSY`EWSBInitialGuess,
                                   FlexibleSUSY`TwoScaleSolver /. solverEwsbSubstitutions,
                                   FlexibleSUSY`TwoScaleSolver /. solverEwsbSolutions,
                                   FlexibleSUSY`TwoScaleSolver /. solverFreePhases,
                                   FlexibleSUSY`TwoScaleSolver /. solverEwsbSolvers,
                                   {{FileNameJoin[{$flexiblesusyTemplateDir, "two_scale_ewsb_solver.hpp.in"}],
                                     FileNameJoin[{FSOutputDir, FlexibleSUSY`FSModelName <> "_two_scale_ewsb_solver.hpp"}]},
                                    {FileNameJoin[{$flexiblesusyTemplateDir, "two_scale_ewsb_solver.cpp.in"}],
                                     FileNameJoin[{FSOutputDir, FlexibleSUSY`FSModelName <> "_two_scale_ewsb_solver.cpp"}]}}];

              Print["Creating class for two-scale model ..."];
              WriteTwoScaleModelClass[{{FileNameJoin[{$flexiblesusyTemplateDir, "two_scale_model.hpp.in"}],
                                        FileNameJoin[{FSOutputDir, FlexibleSUSY`FSModelName <> "_two_scale_model.hpp"}]},
                                       {FileNameJoin[{$flexiblesusyTemplateDir, "two_scale_model.cpp.in"}],
                                        FileNameJoin[{FSOutputDir, FlexibleSUSY`FSModelName <> "_two_scale_model.cpp"}]}}];

              If[FlexibleSUSY`FlexibleEFTHiggs === True,
                 Print["Creating two-scale matching class ..."];
                 WriteSolverMatchingClass[{{FileNameJoin[{$flexiblesusyTemplateDir, "standard_model_two_scale_matching.hpp.in"}],
                                            FileNameJoin[{FSOutputDir, FlexibleSUSY`FSModelName <> "_standard_model_two_scale_matching.hpp"}]},
                                           {FileNameJoin[{$flexiblesusyTemplateDir, "standard_model_two_scale_matching.cpp.in"}],
                                            FileNameJoin[{FSOutputDir, FlexibleSUSY`FSModelName <> "_standard_model_two_scale_matching.cpp"}]}
                                          }];
                ];

              spectrumGeneratorInputFile = "two_scale_high_scale_spectrum_generator";
              If[FlexibleSUSY`OnlyLowEnergyFlexibleSUSY,
                 spectrumGeneratorInputFile = "two_scale_low_scale_spectrum_generator";
                ];
              If[FlexibleSUSY`FlexibleEFTHiggs === True,
                 spectrumGeneratorInputFile = "standard_model_" <> spectrumGeneratorInputFile;
                ];
              Print["Creating class for two-scale spectrum generator ..."];
              WriteTwoScaleSpectrumGeneratorClass[{{FileNameJoin[{$flexiblesusyTemplateDir, spectrumGeneratorInputFile <> ".hpp.in"}],
                                                    FileNameJoin[{FSOutputDir, FlexibleSUSY`FSModelName <> "_two_scale_spectrum_generator.hpp"}]},
                                                   {FileNameJoin[{$flexiblesusyTemplateDir, spectrumGeneratorInputFile <> ".cpp.in"}],
                                                    FileNameJoin[{FSOutputDir, FlexibleSUSY`FSModelName <> "_two_scale_spectrum_generator.cpp"}]}
                                                   }];

              Print["Creating makefile module for two-scale solver ..."];
              WriteBVPSolverMakefile[{{FileNameJoin[{$flexiblesusyTemplateDir, "two_scale.mk.in"}],
                                       FileNameJoin[{FSOutputDir, "two_scale.mk"}]}}];

             ]; (* If[HaveBVPSolver[FlexibleSUSY`TwoScaleSolver] *)

           If[HaveBVPSolver[FlexibleSUSY`SemiAnalyticSolver],
              PrintHeadline["Creating semi-analytic solver"];

              Parameters`AddExtraParameters[SemiAnalytic`CreateBoundaryValueParameters[semiAnalyticSolns]];
              Parameters`AddExtraParameters[SemiAnalytic`CreateCoefficientParameters[semiAnalyticSolns]];

              semiAnalyticSolnsOutputFile = FileNameJoin[{FSOutputDir,
                                                          FlexibleSUSY`FSModelName <> "_semi_analytic_solutions.m"}];
              Print["Writing semi-analytic solutions to ", semiAnalyticSolnsOutputFile];
              Put[SemiAnalytic`ExpandSemiAnalyticSolutions[semiAnalyticSolns], semiAnalyticSolnsOutputFile];

              (* construct additional semi-analytic constraint from user-defined constraints *)
              Which[SemiAnalytic`IsSemiAnalyticConstraintScale[FlexibleSUSY`HighScaleInput],
                    Print["found high-scale"];
                    semiAnalyticScale = FlexibleSUSY`HighScale;
                    semiAnalyticScaleGuess = FlexibleSUSY`HighScaleFirstGuess;
                    semiAnalyticScaleMinimum = FlexibleSUSY`HighScaleMinimum;
                    semiAnalyticScaleMaximum = FlexibleSUSY`HighScaleMaximum;
                    semiAnalyticScaleInput = Cases[FlexibleSUSY`HighScaleInput, FlexibleSUSY`FSSolveEWSBFor[___]];
                    FlexibleSUSY`HighScaleInput = DeleteCases[FlexibleSUSY`HighScaleInput, FlexibleSUSY`FSSolveEWSBFor[___]];,
                    SemiAnalytic`IsSemiAnalyticConstraintScale[FlexibleSUSY`SUSYScaleInput],
                    semiAnalyticScale = FlexibleSUSY`SUSYScale;
                    semiAnalyticScaleGuess = FlexibleSUSY`SUSYScaleFirstGuess;
                    semiAnalyticScaleMinimum = FlexibleSUSY`SUSYScaleMinimum;
                    semiAnalyticScaleMaximum = FlexibleSUSY`SUSYScaleMaximum;
                    semiAnalyticScaleInput = Cases[FlexibleSUSY`SUSYScaleInput, FlexibleSUSY`FSSolveEWSBFor[___]];
                    FlexibleSUSY`SUSYScaleInput = DeleteCases[FlexibleSUSY`SUSYScaleInput, FlexibleSUSY`FSSolveEWSBFor[___]];,
                    SemiAnalytic`IsSemiAnalyticConstraintScale[FlexibleSUSY`LowScaleInput],
                    semiAnalyticScale = FlexibleSUSY`LowScale;
                    semiAnalyticScaleGuess = FlexibleSUSY`LowScaleFirstGuess;
                    semiAnalyticScaleMinimum = FlexibleSUSY`LowScaleMinimum;
                    semiAnalyticScaleMaximum = FlexibleSUSY`LowScaleMaximum;
                    semiAnalyticScaleInput = Cases[FlexibleSUSY`LowScaleInput, FlexibleSUSY`FSSolveEWSBFor[___]];
                    FlexibleSUSY`LowScaleInput = DeleteCases[FlexibleSUSY`LowScaleInput, FlexibleSUSY`FSSolveEWSBFor[___]];,
                    True,
                    semiAnalyticScale = FlexibleSUSY`SUSYScale;
                    semiAnalyticScaleGuess = FlexibleSUSY`SUSYScaleFirstGuess;
                    semiAnalyticScaleMinimum = FlexibleSUSY`SUSYScaleMinimum;
                    semiAnalyticScaleMaximum = FlexibleSUSY`SUSYScaleMaximum;
                    semiAnalyticScaleInput = Cases[FlexibleSUSY`SUSYScaleInput, FlexibleSUSY`FSSolveEWSBFor[___]];
                    FlexibleSUSY`SUSYScaleInput = DeleteCases[FlexibleSUSY`SUSYScaleInput, FlexibleSUSY`FSSolveEWSBFor[___]];
                   ];

              Print["Creating classes for convergence testers ..."];
              WriteConvergenceTesterClass[Complement[Parameters`GetModelParameters[], SemiAnalytic`GetSemiAnalyticParameters[]],
                  {{FileNameJoin[{$flexiblesusyTemplateDir, "susy_convergence_tester.hpp.in"}],
                    FileNameJoin[{FSOutputDir, FlexibleSUSY`FSModelName <> "_susy_convergence_tester.hpp"}]},
                   {FileNameJoin[{$flexiblesusyTemplateDir, "semi_analytic_susy_convergence_tester.hpp.in"}],
                    FileNameJoin[{FSOutputDir, FlexibleSUSY`FSModelName <> "_semi_analytic_susy_convergence_tester.hpp"}]},
                   {FileNameJoin[{$flexiblesusyTemplateDir, "semi_analytic_susy_convergence_tester.cpp.in"}],
                    FileNameJoin[{FSOutputDir, FlexibleSUSY`FSModelName <> "_semi_analytic_susy_convergence_tester.cpp"}]}
                  }
                                         ];
              WriteConvergenceTesterClass[FlexibleSUSY`FSConvergenceCheck,
                  {{FileNameJoin[{$flexiblesusyTemplateDir, "semi_analytic_convergence_tester.hpp.in"}],
                    FileNameJoin[{FSOutputDir, FlexibleSUSY`FSModelName <> "_semi_analytic_convergence_tester.hpp"}]},
                   {FileNameJoin[{$flexiblesusyTemplateDir, "semi_analytic_convergence_tester.cpp.in"}],
                    FileNameJoin[{FSOutputDir, FlexibleSUSY`FSModelName <> "_semi_analytic_convergence_tester.cpp"}]}
                  }
                                         ];

              Print["Creating class for high-scale constraint ..."];
              WriteSemiAnalyticConstraintClass[FlexibleSUSY`HighScale,
                                               Select[FlexibleSUSY`HighScaleInput,
                                                      (!SemiAnalytic`IsSemiAnalyticSetting[#]
                                                       && !SemiAnalytic`IsBasisParameterSetting[#, semiAnalyticSolns])&],
                                               FlexibleSUSY`HighScaleFirstGuess,
                                               {FlexibleSUSY`HighScaleMinimum, FlexibleSUSY`HighScaleMaximum},
                                               SemiAnalytic`IsSemiAnalyticConstraint[FlexibleSUSY`HighScaleInput],
                                               semiAnalyticSolns,
                                               {{FileNameJoin[{$flexiblesusyTemplateDir, "semi_analytic_high_scale_constraint.hpp.in"}],
                                                 FileNameJoin[{FSOutputDir, FlexibleSUSY`FSModelName <> "_semi_analytic_high_scale_constraint.hpp"}]},
                                                {FileNameJoin[{$flexiblesusyTemplateDir, "semi_analytic_high_scale_constraint.cpp.in"}],
                                                 FileNameJoin[{FSOutputDir, FlexibleSUSY`FSModelName <> "_semi_analytic_high_scale_constraint.cpp"}]}
                                               }];

              Print["Creating class for susy-scale constraint ..."];
              WriteSemiAnalyticConstraintClass[FlexibleSUSY`SUSYScale,
                                               Select[FlexibleSUSY`SUSYScaleInput,
                                                      (!SemiAnalytic`IsSemiAnalyticSetting[#]
                                                       && !SemiAnalytic`IsBasisParameterSetting[#, semiAnalyticSolns])&],
                                               FlexibleSUSY`SUSYScaleFirstGuess,
                                               {FlexibleSUSY`SUSYScaleMinimum, FlexibleSUSY`SUSYScaleMaximum},
                                               SemiAnalytic`IsSemiAnalyticConstraint[FlexibleSUSY`SUSYScaleInput],
                                               semiAnalyticSolns,
                                               {{FileNameJoin[{$flexiblesusyTemplateDir, "semi_analytic_susy_scale_constraint.hpp.in"}],
                                                 FileNameJoin[{FSOutputDir, FlexibleSUSY`FSModelName <> "_semi_analytic_susy_scale_constraint.hpp"}]},
                                                {FileNameJoin[{$flexiblesusyTemplateDir, "semi_analytic_susy_scale_constraint.cpp.in"}],
                                                 FileNameJoin[{FSOutputDir, FlexibleSUSY`FSModelName <> "_semi_analytic_susy_scale_constraint.cpp"}]}
                                               }];

              Print["Creating class for low-scale constraint ..."];
              WriteSemiAnalyticConstraintClass[FlexibleSUSY`LowScale,
                                               Select[FlexibleSUSY`LowScaleInput,
                                                      (!SemiAnalytic`IsSemiAnalyticSetting[#]
                                                       && !SemiAnalytic`IsBasisParameterSetting[#, semiAnalyticSolns])&],
                                               FlexibleSUSY`LowScaleFirstGuess,
                                               {FlexibleSUSY`LowScaleMinimum, FlexibleSUSY`LowScaleMaximum},
                                               SemiAnalytic`IsSemiAnalyticConstraint[FlexibleSUSY`LowScaleInput],
                                               semiAnalyticSolns,
                                               {{FileNameJoin[{$flexiblesusyTemplateDir, "semi_analytic_low_scale_constraint.hpp.in"}],
                                                 FileNameJoin[{FSOutputDir, FlexibleSUSY`FSModelName <> "_semi_analytic_low_scale_constraint.hpp"}]},
                                                {FileNameJoin[{$flexiblesusyTemplateDir, "semi_analytic_low_scale_constraint.cpp.in"}],
                                                 FileNameJoin[{FSOutputDir, FlexibleSUSY`FSModelName <> "_semi_analytic_low_scale_constraint.cpp"}]}
                                               }];

              Print["Creating class for semi-analytic constraint ..."];
              WriteSemiAnalyticConstraintClass[semiAnalyticScale, semiAnalyticScaleInput,
                                               semiAnalyticScaleGuess,
                                               {semiAnalyticScaleMinimum, semiAnalyticScaleMaximum}, False, semiAnalyticSolns,
                                               {{FileNameJoin[{$flexiblesusyTemplateDir, "soft_parameters_constraint.hpp.in"}],
                                                 FileNameJoin[{FSOutputDir, FlexibleSUSY`FSModelName <> "_soft_parameters_constraint.hpp"}]},
                                                {FileNameJoin[{$flexiblesusyTemplateDir, "semi_analytic_soft_parameters_constraint.hpp.in"}],
                                                 FileNameJoin[{FSOutputDir, FlexibleSUSY`FSModelName <> "_semi_analytic_soft_parameters_constraint.hpp"}]},
                                                {FileNameJoin[{$flexiblesusyTemplateDir, "semi_analytic_soft_parameters_constraint.cpp.in"}],
                                                 FileNameJoin[{FSOutputDir, FlexibleSUSY`FSModelName <> "_semi_analytic_soft_parameters_constraint.cpp"}]}
                                               }];

              Print["Creating class for initial guesser ..."];
              If[FlexibleSUSY`OnlyLowEnergyFlexibleSUSY,
                 initialGuesserInputFile = "semi_analytic_low_scale_initial_guesser";,
                 initialGuesserInputFile = "semi_analytic_high_scale_initial_guesser";
                ];
              If[FlexibleSUSY`FlexibleEFTHiggs === True,
                 initialGuesserInputFile = "standard_model_" <> initialGuesserInputFile;
                ];
              Which[SemiAnalytic`IsSemiAnalyticConstraint[FlexibleSUSY`HighScaleInput],
                 semiAnalyticInputScale = "high_scale_guess",
                 SemiAnalytic`IsSemiAnalyticConstraint[FlexibleSUSY`SUSYScaleInput],
                 semiAnalyticInputScale = "susy_scale_guess",
                 SemiAnalytic`IsSemiAnalyticConstraint[FlexibleSUSY`LowScaleInput],
                 semiAnalyticInputScale = "low_scale_guess",
                 True,
                 semiAnalyticInputScale = "high_scale_guess"
                ];
              WriteSemiAnalyticInitialGuesserClass[FlexibleSUSY`InitialGuessAtLowScale,
                                                   FlexibleSUSY`InitialGuessAtSUSYScale,
                                                   FlexibleSUSY`InitialGuessAtHighScale,
                                                   semiAnalyticInputScale,
                                                   {{FileNameJoin[{$flexiblesusyTemplateDir, initialGuesserInputFile <> ".hpp.in"}],
                                                     FileNameJoin[{FSOutputDir, FlexibleSUSY`FSModelName <> "_semi_analytic_initial_guesser.hpp"}]},
                                                    {FileNameJoin[{$flexiblesusyTemplateDir, initialGuesserInputFile <> ".cpp.in"}],
                                                     FileNameJoin[{FSOutputDir, FlexibleSUSY`FSModelName <> "_semi_analytic_initial_guesser.cpp"}]}
                                                   }
                                                  ];

              Print["Creating class for semi-analytic solutions ..."];
              WriteSemiAnalyticSolutionsClass[semiAnalyticBCs, semiAnalyticSolns,
                                              {{FileNameJoin[{$flexiblesusyTemplateDir, "semi_analytic_solutions.hpp.in"}],
                                                FileNameJoin[{FSOutputDir, FlexibleSUSY`FSModelName <> "_semi_analytic_solutions.hpp"}]},
                                               {FileNameJoin[{$flexiblesusyTemplateDir, "semi_analytic_solutions.cpp.in"}],
                                                FileNameJoin[{FSOutputDir, FlexibleSUSY`FSModelName <> "_semi_analytic_solutions.cpp"}]}}
                                             ];

              Print["Creating class for semi-analytic EWSB solver ..."];
              WriteSemiAnalyticEWSBSolverClass[ewsbEquations, FlexibleSUSY`EWSBOutputParameters, FlexibleSUSY`EWSBInitialGuess,
                                               FlexibleSUSY`SemiAnalyticSolver /. solverEwsbSubstitutions,
                                               FlexibleSUSY`SemiAnalyticSolver /. solverEwsbSolutions,
                                               FlexibleSUSY`SemiAnalyticSolver /. solverFreePhases,
                                               FlexibleSUSY`SemiAnalyticSolver /. solverEwsbSolvers, semiAnalyticSolns,
                                               {{FileNameJoin[{$flexiblesusyTemplateDir, "semi_analytic_ewsb_solver.hpp.in"}],
                                                 FileNameJoin[{FSOutputDir, FlexibleSUSY`FSModelName <> "_semi_analytic_ewsb_solver.hpp"}]},
                                                {FileNameJoin[{$flexiblesusyTemplateDir, "semi_analytic_ewsb_solver.cpp.in"}],
                                                 FileNameJoin[{FSOutputDir, FlexibleSUSY`FSModelName <> "_semi_analytic_ewsb_solver.cpp"}]}}];

              Print["Creating class for semi-analytic model ..."];
              WriteSemiAnalyticModelClass[semiAnalyticBCs, semiAnalyticSolns,
                                          {{FileNameJoin[{$flexiblesusyTemplateDir, "semi_analytic_model.hpp.in"}],
                                            FileNameJoin[{FSOutputDir, FlexibleSUSY`FSModelName <> "_semi_analytic_model.hpp"}]},
                                           {FileNameJoin[{$flexiblesusyTemplateDir, "semi_analytic_model.cpp.in"}],
                                            FileNameJoin[{FSOutputDir, FlexibleSUSY`FSModelName <> "_semi_analytic_model.cpp"}]}}];

              If[FlexibleSUSY`FlexibleEFTHiggs === True,
                 Print["Creating semi-analytic matching class ..."];
                 WriteSolverMatchingClass[{{FileNameJoin[{$flexiblesusyTemplateDir, "standard_model_semi_analytic_matching.hpp.in"}],
                                            FileNameJoin[{FSOutputDir, FlexibleSUSY`FSModelName <> "_standard_model_semi_analytic_matching.hpp"}]},
                                           {FileNameJoin[{$flexiblesusyTemplateDir, "standard_model_semi_analytic_matching.cpp.in"}],
                                            FileNameJoin[{FSOutputDir, FlexibleSUSY`FSModelName <> "_standard_model_semi_analytic_matching.cpp"}]}
                                          }];
                ];

              spectrumGeneratorInputFile = "semi_analytic_high_scale_spectrum_generator";
              If[FlexibleSUSY`OnlyLowEnergyFlexibleSUSY,
                 spectrumGeneratorInputFile = "semi_analytic_low_scale_spectrum_generator";
                ];
              If[FlexibleSUSY`FlexibleEFTHiggs === True,
                 spectrumGeneratorInputFile = "standard_model_" <> spectrumGeneratorInputFile;
                ];
              Print["Creating class for semi-analytic spectrum generator ..."];
              WriteSemiAnalyticSpectrumGeneratorClass[{{FileNameJoin[{$flexiblesusyTemplateDir, spectrumGeneratorInputFile <> ".hpp.in"}],
                                                        FileNameJoin[{FSOutputDir, FlexibleSUSY`FSModelName <> "_semi_analytic_spectrum_generator.hpp"}]},
                                                       {FileNameJoin[{$flexiblesusyTemplateDir, spectrumGeneratorInputFile <> ".cpp.in"}],
                                                        FileNameJoin[{FSOutputDir, FlexibleSUSY`FSModelName <> "_semi_analytic_spectrum_generator.cpp"}]}
                                                      }];

              Print["Creating makefile module for semi-analytic solver ..."];
              WriteBVPSolverMakefile[{{FileNameJoin[{$flexiblesusyTemplateDir, "semi_analytic.mk.in"}],
                                       FileNameJoin[{FSOutputDir, "semi_analytic.mk"}]}}];

              Parameters`RemoveExtraParameters[SemiAnalytic`CreateBoundaryValueParameters[semiAnalyticSolns]];
              Parameters`RemoveExtraParameters[SemiAnalytic`CreateCoefficientParameters[semiAnalyticSolns]];
             ]; (* If[HaveBVPSolver[FlexibleSUSY`SemiAnalyticSolver] *)

           PrintHeadline["Creating observables"];
           Print["Creating class for effective couplings ..."];
           (* @note separating this out for now for simplicity *)
           (* @todo maybe implement a flag (like for addons) to turn on/off? *)
           WriteEffectiveCouplings[effectiveCouplings, FlexibleSUSY`LowScaleInput, massMatrices, vertexRules,
                                   {{FileNameJoin[{$flexiblesusyTemplateDir, "effective_couplings.hpp.in"}],
                                     FileNameJoin[{FSOutputDir, FlexibleSUSY`FSModelName <> "_effective_couplings.hpp"}]},
                                    {FileNameJoin[{$flexiblesusyTemplateDir, "effective_couplings.cpp.in"}],
                                     FileNameJoin[{FSOutputDir, FlexibleSUSY`FSModelName <> "_effective_couplings.cpp"}]}
                                   }];

           Print["Creating class for observables ..."];
           WriteObservables[extraSLHAOutputBlocks,
                            {{FileNameJoin[{$flexiblesusyTemplateDir, "observables.hpp.in"}],
                              FileNameJoin[{FSOutputDir, FlexibleSUSY`FSModelName <> "_observables.hpp"}]},
                             {FileNameJoin[{$flexiblesusyTemplateDir, "observables.cpp.in"}],
                              FileNameJoin[{FSOutputDir, FlexibleSUSY`FSModelName <> "_observables.cpp"}]}}];

           Print["Creating class GMuonMinus2 ..."];
           WriteGMuonMinus2Class[vertexRules,
                                 {{FileNameJoin[{$flexiblesusyTemplateDir, "a_muon.hpp.in"}],
                                   FileNameJoin[{FSOutputDir, FlexibleSUSY`FSModelName <> "_a_muon.hpp"}]},
                                  {FileNameJoin[{$flexiblesusyTemplateDir, "a_muon.cpp.in"}],
                                   FileNameJoin[{FSOutputDir, FlexibleSUSY`FSModelName <> "_a_muon.cpp"}]}}];

           PrintHeadline["Creating Mathematica interface"];
           Print["Creating LibraryLink ", FileNameJoin[{FSOutputDir, FlexibleSUSY`FSModelName <> ".mx"}], " ..."];
           WriteMathLink[inputParameters, extraSLHAOutputBlocks,
                         {{FileNameJoin[{$flexiblesusyTemplateDir, "librarylink.cpp.in"}],
                           FileNameJoin[{FSOutputDir, FlexibleSUSY`FSModelName <> "_librarylink.cpp"}]},
                          {FileNameJoin[{$flexiblesusyTemplateDir, "librarylink.m.in"}],
                           FileNameJoin[{FSOutputDir, FlexibleSUSY`FSModelName <> "_librarylink.m"}]},
                          {FileNameJoin[{$flexiblesusyTemplateDir, "run.m.in"}],
                           FileNameJoin[{FSOutputDir, "run_" <> FlexibleSUSY`FSModelName <> ".m"}]}
                         }];

           PrintHeadline["Creating user examples"];
           Print["Creating user example spectrum generator program ..."];
           WriteUserExample[inputParameters,
                            {{FileNameJoin[{$flexiblesusyTemplateDir, "run.cpp.in"}],
                              FileNameJoin[{FSOutputDir, "run_" <> FlexibleSUSY`FSModelName <> ".cpp"}]},
                             {FileNameJoin[{$flexiblesusyTemplateDir, "run_cmd_line.cpp.in"}],
                              FileNameJoin[{FSOutputDir, "run_cmd_line_" <> FlexibleSUSY`FSModelName <> ".cpp"}]},
                             {FileNameJoin[{$flexiblesusyTemplateDir, "scan.cpp.in"}],
                              FileNameJoin[{FSOutputDir, "scan_" <> FlexibleSUSY`FSModelName <> ".cpp"}]}
                            }
                           ];

           Print["Creating example SLHA input file ..."];
           WriteSLHAInputFile[inputParameters,
                              {{FileNameJoin[{$flexiblesusyTemplateDir, "LesHouches.in"}],
                                FileNameJoin[{FSOutputDir, "LesHouches.in." <> FlexibleSUSY`FSModelName <> "_generated"}]}}
                             ];

           PrintHeadline["FlexibleSUSY has finished"];
          ];

End[];

EndPackage[];
