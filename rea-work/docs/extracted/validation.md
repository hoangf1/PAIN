# NASA-CR-172428 validation (OCR extract)

> Machine-extracted text from the corresponding PDF. OCR errors are expected; prefer the PDF for authoritative wording.

```text
 NASA       Contractor                Report      172428




 Propeller Aircraft                                 Interior Noise Model

 Utilization               Study          and Validation
      {NAS_-CR-        172428)        PROFELLER      _ISCR&FT                        N87-I       1576
     IN'IERIO_         NOISÂ£     MOÂ£EL     UTILIZATICN      STUDY    AND                                â€¢
     VALIDATION            [Pcpe     (i. E.))       248  p      CSCL     20A
                                                                                     Unclas
..                                                                             G3/71 .3_.9
L.D.    Pope




L.D.POPE,              PH.D.,        P.E./CONSULTING          ENGINEER
The     Woodlands,              TX     77380


                                                                                    -_,,_ -_-G

CONTRACT          NA51-17281
September      1984




National Aeronautics    and
Space Administration

Langley Research Center
Hampton, Virginia 23665
NASA        Contractor             Report       172428




Propeller Aircraft Interior Noise Model

Utilization              Study          and Validation




L.D.    Pope




L.D.POPE,          PH.D.,         P.E./CONSULTING        ENGINEER

The     Woodlands,           TX     77380




CONTRACT          NAS1-17281
September      1984




National Aeronautics   and
Space Administration

Langley Research Center
Haml:)ton, Virginia 23665
                                    TABLE         OF     CONTENTS




      2.1   The      PAIN     Model         .     .     . .       .   .   .   .   .   .   .   .   .   .   .   .    3

      2.2   PAIN      Program          Description...........                                                      7

      2.3   Report          Organization                     .    .   .   .   .   .   .   .   .   .   .   .   .    8



3.0   SCALE-MODEL           TESTS      AND        COMPARISONS.........                                            10



      3.1   Test      Configuration                     . .       .   .   .   .   .   .   .   .   .   .   .   .   15

            3.1.1           Fuselage              â€¢     â€¢.        â€¢   â€¢   â€¢   â€¢   â€¢   â€¢   â€¢   â€¢   â€¢ â€¢     â€¢   â€¢   15

            3.1.2           Trim       .     â€¢    . .        . .      .   .   .   .   .   .   .   .   .   .   .   16

            3'1.3           Propeller...............                                                              17

      3.2   Description              of     Tests.............                                                    17

      3.3   Measurement              Results                 . .      .   .   .   . .     .   .   . .     .   .   21

            3.3.1           Loss     factors                 . .      .   . .     . .     . .     . .     .   .   21

            3.3.2           Propeller             noise............                                               24

             3.3.3          Interior             sound           levels.........                                  24

      3.4    Computer         Simulation                 of       Scale-Model             Tests       .   .   .   43

             3.4.1          Fuselage             modeling...........                                              49

             3.4.2          Propeller             modeling                â€¢   â€¢   â€¢   â€¢   â€¢   â€¢   â€¢   â€¢   â€¢   â€¢   53

             3.4.3          Propeller             noise           predictions             and

                                    comparisons............                                                       56

      3.5   Test      Comparisons...............                                                                  71

             3.5.1          Structural                damping             â€¢   â€¢   â€¢   â€¢   â€¢   â€¢   â€¢   â€¢   â€¢   â€¢   71

             3.5.2          Acoustic             loss        factors.........                                     74

             3.5.3          Interior             sound           levels       .   .   .   .   .   .   .   .   .   76




                                                        -i-
                        TABLE OF             CoNTENTs                 (Continued)




4.0   PROGRAM         UTILIZATION:                  FULL          SCALE           AIRCRAFT               .   . .     .   89



      4.1      Modeling         of     the         Aircraft                  .    .   .    . .       .   .   .   .   .   89

      4.2      Modeling          for     Cabin              and       Fuselage             Modes         .   .   .   .    96

               4.2.1          Cabin          .     .    .    . .        .    .    .    .   .    .    .   .   .   .   .    96

                4.2.2         Fuselage             .    .    .    .     .    .    â€¢    â€¢   â€¢    â€¢    â€¢   â€¢   â€¢   â€¢   â€¢    97

      4.3      Modal         Characteristics                      of        Typical            Airplanes             .   105

                4.3.1         Acoustic             Modes.......                                      â€¢   â€¢   â€¢   â€¢   â€¢   105

                4.3.2         Structural                Modes.........                                           â€¢   â€¢   107

      4.4       Computation            Times.........                                                â€¢   â€¢   â€¢   â€¢   â€¢   115



5.0   FLIGHT      TEST        CoMPARISONS                    .    .     .    .    .    .   .    .    .   .   .   .   .   118



      5.1       Description             of        Aircraft.....                                 â€¢    â€¢ â€¢     â€¢ â€¢     â€¢   118

      5.2       Test     Program              .    .    .    .    .     .    .    .    .   .    .    .   .   .   .   .   121

                5.2.1         Interior             Measurements                        .   . .       .   .   .   .   .   124

                5.2.2         Space-Average                      Levels......                                â€¢   â€¢   â€¢   127

      5.3       Computer         Simulation                  of       Flight           Tests         .   .   .   .   .   137

                5.3.1         ANOPP      Prediction                     Methodology.....                                 137

                5.3.2         Predicted                Exterior              Levels              .   .   .   .   . .     140

                5.3.3         Fuselage             and        Cabin          Modeling                .   .   .   .   .   151

                5.3.4         PAIN      Input           and       Output              Data......                         151

      5.4       Comparisons             to        Flight          Test           Results             .   .   .   â€¢   â€¢   155

      5.5       Understanding                 Sidewall                 Transmission.....                                 165



6.0   FINDINGS          AND     CONCLUSIONS                   .    .    .     .   .    .   .     .   .   .   .   .   .   166



      6.1       Use     of    the      PAIN        Program.........                                              â€¢   .   167

      6.2       PAIN     Validation                Status               .     .   .    .    .    .   .   ....            167




                                                              -ii-
                     TABLE     OF    CONTENTS   (Continued)




REFERENCES        . .    . . . .     . . . . . .     . . .    . . .   . .   . .   169




      Analytical         Modification      of PAIN
      Program      Changes
      Control      Card    Changes




      Scale     Model     Predictions




      Modal      Characteristics
         Business        Aircraft

         Small     Body    Aircraft
         Narrow     Body     Aircraft




      Flight      Test    Predictions




                                            -iii-
                                                       LIST        OF       FIGURES



            Figure    No.



               I @   Propeller          Aircraft                Interior               Noise            Model           .       .   â€¢   â€¢     â€¢    4
              2.     Propeller          and       Fuselage                 Surface               Point           Geometry               .     .    5
                     Grid    Used       for       Propeller                 Noise            Predictions                        .   .   â€¢     â€¢    6
              3.
                                                                                                                                                  11
              4.     Model      Test        Facility.....                                    â€¢    â€¢     â€¢    â€¢     â€¢    â€¢       â€¢   â€¢   â€¢     â€¢
                                                                                                                                                  12
              5.     Fuselage          Model           .    .     .    .     .    â€¢     â€¢    â€¢    â€¢     â€¢    â€¢     â€¢    â€¢       â€¢   â€¢   â€¢     â€¢

              6.     Floor      Assembly               .    .     .    .     .    â€¢     â€¢    â€¢    â€¢     â€¢    â€¢     â€¢    â€¢       â€¢   â€¢   â€¢     â€¢   13

              7.     Cross-Section                of       Test        Cylinder                  Showing               Trim         .   .     .   14

              8.     Propeller          Tests.......                                         â€¢     â€¢    â€¢    â€¢     â€¢    â€¢       â€¢   â€¢     â€¢   â€¢   19

              9.     Free     Field         Propeller                 Tests             .    .     .    .    .     .    â€¢       â€¢   â€¢ â€¢       â€¢   2o

             10.     Microphone             Locations                 for        Blocked               Pressure

                      Measurements                .    .    .     .     .    .    .     â€¢    â€¢     â€¢    â€¢    â€¢     â€¢    â€¢       â€¢   â€¢     â€¢   â€¢   22

             11.     Measured          Free       Field           Noise-Propeller                            at        3000         RPM       .   25
             12.     Measured          Free       Field           Noise-Propeller                            at        4000         RPM       .   26

             13.     Measured          Free       Field           Noise-Propeller                            at        5000         RPM       .   27

              14.    Spectrum          of     Free         Field            Propeller                  Noise           at

                      Microphone              I   .    .    .     .     .    .    .     .    .     .    â€¢    â€¢     â€¢     â€¢      â€¢   â€¢     â€¢   â€¢   28
              15.    Phase      Measurements,                     4000           RPM         .     .    .    .     .     .      .   .     â€¢   â€¢   29

              16.    Phase      Measuremeats,                     5000           RPM         .     .    .    .     .     .      .   .     â€¢   â€¢   30

              17.    Typical        Interior               Spectrum.........                                                        â€¢     â€¢   â€¢   31

              18.    Axial      Variation              of       Average                Sound           Pressure

                      Level      by     Major          Subvolume                   (3000           RPM)            .     .      .   .     .   .   44
              19.    Axial      Variation              of       Average                Sound           Pressure

                      Level      by     Major          Subvolume                   (4000           RPM)            .     .      .   .     .   .   45
             20.     Axial      Variation              of       Average                Sound           Pressure

                      Level      by     Major          Subvolume                   (5000           RPM)            .     .      .   .     .   .   46
              21.    Measured          Sound          Levels            Inside              Model           Fuselage

                       Induced         by     Propeller..............                                                                             48
              22.    Typical        Pressure               Signature                   and        the       PAIN

                       Program         Fourier             Representation.....                                                  â€¢   â€¢     â€¢   â€¢   57
              23.    Comparison             of    Propeller                  Noise           Predictions

                       and     Measurements,                    3000         RPM         .    .    .     .     .   â€¢        .   â€¢   â€¢     â€¢   â€¢   62




                                                                             -iv-


L   â€¢   â€¢
                             LIST       OF     FIGURES         (Continued)


Figure    No.


 24.     Comparison              of    Propeller           Noise     Predictions
          and     Measurements,                    4000    RPM...........                                   63
 25.     Comparison              of    Propeller           Noise     Predictions
          and     Measurements,                    5000    RPM...........                                   64
 26.     Propeller           Tones        Phase       Prediction,             3000     RPM     .     . .    65
 27.     Propeller           Tones        Phase       Prediction,             4000     RPM     .     . .    66
 28.     Propeller           Tones        Phase       Prediction,             5000     RPM     .     . .    67
 29.     Measured           Free       Field        aud    Blocked          Sound     Levels

          Induced           by    Propeller            . . .       . . .       . . .     . . .       . .   69
 30.     Measured           and       Predicted           Blocked          Sound    Levels

          Induced           by    Propeller           on     Test      Cylinder          . . .       . .    7o
 31.     Predicted           and       Measured           Structural          Loss     Factors

          of Fuselage   with Trim                         Installed,    WT=0.13    . .               . .    73
 32.     Predicted   and Measured                         Acoustic   Loss   Factors                  . .    75
 33.     Measured           and       Predicted           Levels     Inside         Model

         Fuselage           Induced           by    Propeller..........                                    177
 34.     Measured           and       Predicted           Sound     Levels,         Blocked
          Field     Limited              to    4    dB Maximum             Increase      . . .       . .    78
 35.     Measured           and       Predicted           Sound     Levels,         Blocked
          Field=4           dB    (Max),           Critically        Damped         Trim     Panel     .    87
 36.     Business/Commuter                     Aircraft            . . .       . . .     . . .       . .    9O
 37.     Small     Body          Aircraft           . . . .        . .      . . . .      . . .       . .    91
 38.     Narrow     Body          Aircraft-Propfam                  Configuration              .     . .    92
 39.     Variation           of       Overall        Free      Field        Propeller
          Levels        .    . . . .           . . .       . .     . . .       . . .     . . .       . .    95
 40.     Cabin     Floor          Angles            . . . .        . .      . . . .      . . .       . .    98
 41.     Typical        Aircraft              Construction             .    . . . .      . . .       . .   102
 42.     Cabin     of       Aircraft           Showing         Seating        and     Micro-
          phone     Locations                  . . .       . .     . .      . . . .      . . .       . .   119
 43.     Microphone              Sweep        Path     for     Space        Average      (About
          15     Sec/Circuit              Traversed           Twice)           . . .     . . .       . .   ia5


                                                             -V-
                          LIST      OF    FIGURES        (Continued)



Figure    No.


 44.     Typical     Interior            Measurement               .    . .       . . .        â€¢ â€¢ â€¢         â€¢   130

 45.     Amplitude        Comparison,            Full        Blade          vs.     Compact
          Chord     Formulations...                      â€¢    â€¢ â€¢       â€¢ â€¢       â€¢ â€¢     â€¢ â€¢ â€¢ â€¢            â€¢   138

 46.     Phase     Comparison             . . . .        â€¢ â€¢ â€¢          â€¢ â€¢ â€¢ â€¢           â€¢ â€¢       â€¢ â€¢ â€¢        139

 47.                                                                                                             141
         Phase     Comparison            When    Adjusted              to    Means        _H        "    " "
 48.     Exterior        Levels        (Free     Field),           Flight          Run     No.          10   .   143

 49.     Phase     (Free        Field),      Flight          Run       No.    10     . . .          . . â€¢        144

 50.     Exterior        Levels        (Free     Field),           Flight           Run    No.          11   .   146

 51.     Phase     (Free        Field),      Flight          Run       No.     11    .     . . . . .             147

 52.     Exterior        Levels        (Free     Field),           Flight           Run    No.          12   .   149

 53-     Phase     (Free        Field),      Flight          Run       No.     12    .     . . ,         .   .   150
 54.     Effect     of    Varying         Loss      Factor,            _T    on     Trim
          Factor         _t=    cWl2        . â€¢ .    â€¢ . . .            . . .        . .       â€¢ . . â€¢           153

 55.     Space-Average              Sound    Levels          Inside          Aircraft           @
          238     KIA_     (Altitude=5000               ft.)        . . .         . . .        . . . â€¢           158

 56.     Space-Average              Sound    Levels          Inside          Aircraft           @
          216 KIAS         (Altitude=5000               ft.)        . .      . . .         . . .         . â€¢     159

 57.     Space-Average              Sound    Levels          Inside          Aircraft           @
           165 KIAS        (Altitude=5000               ft.)        .    . . . .           . . .         . .     16o

 58.     Comparison            of   Predictions          and       Measurements
          Without        Assumed         Bias    Corrections.......                                          â€¢   162




                                                     -vÂ±-
                                       LIST       OF TABLES


Table   No.


   I.   Measured      Acoustic             and    Structural            Loss      Factors       . .   23
  2.    Interior     Measurements-                      3000     RPM,     Harmonic
         No.     I (150        Hz)    . .       . .     . . .     . . .         . . .    . .    . .   32
  3.    Interior      Measurements-                     4000     RPM,     Harmonic
         No.     1 (200        Hz)    . .       . . . .         . . . .         . .   . . .     . .   35
                                                                           "k


  4.    Interior      Measurements-                     5000     RPM,     Harmonic
         No. I (250 Hz) . . . . . . . . . . . . . . . . .                                             38
  5.    Measured      Space          Average           Sound     Pressure         Levels,
         Emtire      Cabin       Space          (Above     Floor)         . .     . . .       . . .   47
  6.    Input     Data     Used       to    Simulate            Scale     Model       Tests     . .   51
  7.    ANOPP     Predictions              of    Propeller         Noise,         Grid
         Line     e=I,0.762           m    Dia.,        3 Bladed         Hartzell
         Propeller         @ 3000          RPM     . . . . .            . . .     . .    . . .    .   58
  8.    ANOPP     Predictions              of    Propeller         Noise,         Grid
         Line     e=I,0.762           m    Dia.,        3 Bladed         Hartzell
         Propeller         @    4000       RPM     .    . . .     . . .         . . .    . .    . .   59
  9.    ANOPP     Predictions              of    Propeller         Noise,         Grid
         Line     e=1,0.762           m Dia.,           3 Bladed         Hartzell
         Propeller         @    5000       RPM..............                                          6O
 10.    Predicted         Versus          Measured        Space         Average
         Sound     Pressure           Levels            . .     . .     . . .     . . .       . . .   79
 11.    Sample     Statistics              and     Acceptance            Regions
         for     Interior        Sound          Levels         (Table     10)     . .    . . . .       82
 12.    Predicted         Versus          Measured        Space         Average
         Sound     Pressure           Levels            . . .      . . . .        . .    . . .    .    86
 13.    Selected      Fuselage             Characteristics........                                     99
 14.    Program      Run-Times             (Typical)            . .     .........                     116

 15.    Flight     Tests             . . .       . .    . . .      . . .        . . .    . . .    .   123
  16.   Interior      Measurements..............                                                      128
 17.    Differences            Between          Average         Sound     Levels
         in     Forward        and    Middle           Subvolumes........                             132



                                                      -vii,
                            LIST      OF   TABLES         (Continued)



Table   No.



 18.    Results       of     Hypothesis          Tests.........                                        â€¢   â€¢   133

 19.    Measured       Space         Averages         and      Confidence                Limits        .   .   136

 20.    Exterior       Levels         in     Flight       Run     No.     10        (ANOPP

         Compact       Chord,         free       field,        e=1)       .     â€¢    .    â€¢    â€¢   â€¢   â€¢   â€¢   142

 21.    Exterior       Levels         in     Flight       Run     No.     11        (ANOPP

         Compact       Chord,         free       field,        e=1)       .     â€¢    â€¢    â€¢    â€¢   â€¢   â€¢   â€¢   145
 22.    Exterior       Levels         in     Flight       Run     No.      12       (ANOPP

         Compact       Chord,         free       field,        e=1)       .     .    â€¢    â€¢    â€¢   â€¢   â€¢   â€¢   148

 23.    Predicted          Versus      Measured           Space         Average

         Sound      Pressure          Levels       in     Flight           .    .    .     .   .   .   .   â€¢   156

 24.    Sample      Statistics             and    Acceptance             Regions
         for      Interior         Sound      Levels        (Table        23)        â€¢     â€¢   â€¢   â€¢   â€¢   â€¢   157

 25.    Predictions           with     High       Frequency             Formulation                .   .   .   164




                                                      -viii-
I. 0     SUMMARY


This     report      considers            the    utilization               and    the       validation             of   a
computer       program         designed           for       aircraft        interior             noise       predic-
tion.        The    program,         entitled           PAIN,       permits        (in       theory)          pre-
dictions       of    sound         levels       inside        propeller           driven          aircraft
arising       from    sidewall            transmission.                The       objective             of    the
present       work    is      to    determine           the    practicality                 of    making       pre-
dictions       for    various            airplanes           and    the     extent          of    the       program's
                         \


capabilities.                The    ultimate           purpose        is    to    discern             the    quality
of     predictions           for    tonal       levels        inside        an    aircraft             occurring
at     the   propeller         blade          passage        frequency           and    its       harmonics.
This     effort      involves            three     tasks:


         I)    program         validation              through        comparisons                of    predictions
               with     scale-model               test       results,


         2)    development               of    utilization            schemes          for       large       (full
               scale)         fuselages,           and


         3)    validation            through           comparisons           of    predictions                with
               measurements               taken        in    flight        tests       on    a turboprop
               aircraft.


Findings       should         enable          future        users     of    the    program             to    effi-
ciently       undertake            and    correctly           interpret           predictions.




                                                        -I-
2.0      INTRODUCTION



PAIN      (an        acronym         for    Propeller               _Aircraft            Interior                  Noise)           is

a    computer          program            that     has        been        developed               for           predicting
sound        levels          inside        an     airplane            caused           by        the        rotation            of

a    propeller           (of     any       design)            alongside.                 PAIN              can     calculate

the     tonal         levels        in     the      cabin          space         occurring                  at     the      pro-

peller         blade         passage          frequency              and     its        harmonics.



PAIN     mechanizes              an       analytical               model         that           can        be     found        in

Reference             (I).       The       program's               Users'         Manual,                  Ref.        (2),     con-

tains         a basic          overview           of     the       mechanization                      and         specifies

the     input         data      requirements.                      There         are     some              features            of
the     PAIN         model      that       make        it     unique         in    interior                     noise         work:



I)      it     requires             a precise            description                of          the        propeller            noise

        signature              (pressure            field)           on    the         fuselage                 skin,



2)       fuselage            sidewall            dynamic           restraint             offered                  by    a     struc-

         turally         integral             stiffened              floor        in        a    ring-stringer

         stiffened             cabin        shell        is     included,               and



3)       the     acoustic             modes       of     the       complex             cabin           configuration

         (with         floor        partition)               are     utilized;                  cabin            acoustic            and

         fuselage            structural             modal          losses          are          computed               using         the

         sidewall            trim        properties.



Theoretical              developments,                      experiments,                and           validation                studies

that      preceded             PAIN        and    culminated                in     its          invention                are        docu-

mented          in    Refs.         (3)     through            (6).         Some        preliminary                      validation

of     PAIN      for     propeller               noise         prediction               is       given            in     Appendix               E

of     Ref.      (I).          However           the     work         reported              herein               should        be        con-

sidered          the     fundamental                validation               of        the       model.                Here,         the

quality          of     PAIN        interior           noise          predictions                     is        explored            through




                                                                -2-
more      extensive               comparisons                 with        scale,         model           and        flight             tests'
results.              The       primary            goal       is     to        develop             insight           into          the
use     of     PAIN        as     a    tool        to    make        reliable                 full-scale                 aircraft

 predictions.


 2.1      The        PAIN       Model


 The     elements            of       the       PAIN      model       include                 a    fuselage              and       a    pro-

 peller        (Figures               I and        2).        The      fuselage                   consists              of    a    cylin,
 der     stiffened              by     ring        frames           and        stringers,                 and       a    flDor          that
â€¢is    structurally                   an    integral               part        of    the          fuselage.                  The       in-

 terior        surface            of       the     cabin           (sidewall)                 is    finished                 out       with

 a    trim     consisting                  of    insulation                covered                with       a lining.                  The
 propeller            rotates              about         an    axis        parallel                to     the center                   line
 of    the      fuselage.                  PAIN        will        predict           the          space       average              sound
 pressure            levels           in     the       cabin        space           at    each          of    the        harmonics
 of    the     propeller               (up        to     a maximum              of       ten       (10)       harmonics).


 PAIN     works           with        the       pressure            time        histories                 (signatures)                   as
 defined           over      the       fuselage               at    a number              of       closely              spaced
 points         on    a grid           that        lies        in     the       fuselage                 skin       (Fig.          3).
 The     pressures               can       be     specified               at    up       to       160     points             on    the
 upper        quarter            surface           of     the       fuselage              nearest              the       propeller.
 Fourier           series         are        used        to    define           the       amplitudes                    and       phases
 of     each       harmonic            (at        each        location).                  PAIN           then       generates
 data        for     an     identical              grid        on     the       lower             quarter           surface             of
 the     fuselage            nearest              the     propeller                 (using           the       data          input
 for     the       upper         grid).            The        propeller              data          must        be       generated
 with        a propeller               noise           prediction               program              such       as       PROPFAN
 (7)     or    NASA         ANOPP           (Aircraft              Noise        Prediction                   Program)              (8).




 Structural               properties                of    the        cylinder             and        floor          are       required
 as     input        data        to    compute            the        fuselage              structural                   modes




                                                                     -3-
    ORIGINAL   PAGE Ig
    OF POOR    QUALITY
N




                             /




                                                                        .J
                                                                        L_

                                                                        C
                             /                                          :E
                                                                        V%
                                                                        m

                                                                        @
                                                                        Z

                                                                        @
                                                                        m




                                                                        Z

                                                                        LL


                                                                        U
                                                                        i

                                 0
                                 Â¢_1
                                       0
                                       I.-
                                             0   0
                                                 _,-
                                                          0
                                                          Â¢_1
                                                                  0
                                                                  Â¢Fj
                                                                        .<
                                                  I        I       I

                         x   Id'lJrllltiJd             oltlnooy         _J
                                                                        .J

                                                                        _L




                                                                            I

                                                                            LL.




                                 L




                 -4.
                                               ORIGINAL       PAGE     iS

                       Propeller     Plane OF POOR            QUALITY
                                                                               FUSELAGE


                                         /
                                     I

                                                                              _7 = Incidence         Angle




                                                                       n       =_

                                                                            P I_1



                                                     rp


         Y                                                                               Propeller




                                                          X




                                                          _m = (a,            e,    z)    = Location  of Free
                                                                                            Field Prediction
                                                                                            Point

                                                                     (rp,_,          Zp)     = Propeller     Position




              y




FIGURE   2.       PROPELLER        AND       FUSELAGE     SURFACE                  POINT     GEOMETRY        [ 1 ]



                                               -5-
         ORIGINAL   PAGE IS
                                    u3
         OF POOR    QUALITY         I.u
N
    II
                                    Z
                              /



                                  _Ux




                                          w



                                          Z
                                          C_
                                          m


                                          LJ

                                          LU


                                          L_
                                          m


                                          Z

                                          LU
                                          m

                                           LU

                                           0



                          x                   @

                                              C_
                                              UJ


                                              m


                                              L;



                                              1,1


                                              m
                                              11




         -6-
(resonance               frequencies              and     mode       shapes).               Associated            struc-

tural     loss           factors        must        be    input       if       the     cabin        is    bare,        but
if     trim     is       installed,            the       required          modal        loss        factors          are
computed         for          the     particular           trim       installation                  (estimates
for     the     bare          fuselage         may       still       be    input).


Similarly,               acoustic          modal         properties             of     the     cabin       space        (reso-

nance        frequencies,               mode        shapes,          and       loss      factors)          are       calcu-
lated        from        _nput        data     specifying             the        cabin       shape        (floor

angle,        8 o'       of    Figure        I,     and    the       cabin        length)           and    the       trim
properties.


Transmission                  and     absorption           characteristics                     of    the       trim     (at
a given         frequency)               are      computed           using        input        data       for     the
wave     impedance               and     complex          acoustic             wavenumber            in    the       insu-
lation,         and       the       trim     lining         surface            weight        and     its       loss
factor         (theoretically                  as    measured             installed).


A    step-by-step               procedure            to    be     followed             in    parameterizing
the     interior              noise     model        is    given          in     Section          3.0     of    Ref.       (2).

Elaboration               on     the    procedure              and    on       the     preparation              of     input
data     for     full          scale       aircraft            predictions              is     a major          focus
of    this      report.


2.2      PAIN        Program           Descrintion


The     main     program              PAIN     computes          and       outputs           the     interior           sound

levels.          It       requires           (as     input)          data        that       are     generated           by
four     auxiliary              programs.                One    of    the        auxiliary           programs           cal-
culates         the       acoustic           modal        properties              of    the       cabin,        two
other     programs              the     structural              modal          properties            of    the       fuse-
lage,     and        a    fourth        the     propeller             noise          field.


The     acoustic              modes     are       calculated              with       the     program           CYL2D       which




                                                               -7-
determines           the     two-dimensional                       (cabin          cross-section)                   modal

characteristics                  (floor          present),              conditions             the       results         and
writes       the     data        on    a    file       (tape)           for    recall          by       the     main
program.           PAIN      uses          the    data        to       generate          the       complete           three-
dimensional            modal          set    required              for     the      noise          predictions.


The     structural           modal          data       are       generated           with          a program           called
MRPMOD       whose      output          is       also       to     a    file       (tape)          read       by    PAIN.
In     addition        to    its       own       input        data,       MRPMOD          reads          two       files
(tapes)        that     are       used       for       output           from       the    fundamental                 struc-
tural     program           MRP.        MRP       computes              the    mode       shapes          and       reso-
nance     frequencies,                 and       must       be     run    twice,          once          for     the    symme-
tric     modes       and     once          for    the       antisymmetric                 modes.              The     two
files     (tapes)           created          by       these        runs       are    read          by    MRPMOD,         which
conditions           these        data        for      PAIN.


As     stated,       the     propeller                noise        data       must       be    calculated              with

a propeller            noise          prediction              program,             such       as    the       NASA
Langley        PROPFAN           (7)    program             or     that       of    ANOPP          (8).         This     aux-
iliary       program         is       not    part        of      PAIN     as       are    the       programs           CYL2D,
MRP,     and     HRPMOD.


Section        4.0     of    Ref.          (2)    should           be    consulted             for       an     expanded
overall        program           description                with        accompanying                flow        chart.
Sections         5.0    and       6.0       of    Ref.        (2)       deal       with       the       input       data     re-
quirements           and     control             cards.


2.3      Report        Organization


In    this     report,           comparisons                are        first       made       between           predictions
and     measurements              from       a set          of     scale       model          experiments.                  Next
consideration               is    given          to    the       application              of       the    PAIN        program
to    real     aircraft,              and    to       the     development                of    utilization
schemes        that     Will          allow       its       efficient              use    on       a    full        scale




                                                              -8-
airplane.    Comparisons      are    then   made between   PAIN predictions
and flight   test   results    for    a particular   propeller-driven
airplane.




                                       -9-
3.0        SCALE-MODEL             TESTS          AND     COMPARISONS


The     tests         considered             in     this      section           provide          results           for     the
most       direct          type    of       comparison             of    PAIN        predictions              and
measurements.                    All    of     the       basic        elements            of    the     analytical

model       are       present          in    the     test        hardware            and       the     test       rig.
Nothing          is    present          that        does      not       have     an       analytical              counter-
part.           The    PAIN       model        (Figure           I)     is    a propeller               excited          seg-
ment       of    a cylindrical                 fuselage            stiffened              by    rings        and    string-
ers,       with       an    integral           stiffened              floor      and       sidewall            trim
(lacking          wings          and    empennage).                   This      is    exactly           the       descrip-

tion       of    the       scale-model              hardware            and     test       configuration
shown       in    Figures          4    through           7.1         When      PAIN       is    applied           to    real

aircraft,             the    problem           of    fuselage            modeling              must     be     addressed;
effects          of    non-uniformity                    of   cross-section,                    presence           of    wings

and     empennage,               etc.,       may     need        to     be    examined.                Here,       how-
ever,       a simple             question           is    asked:         "How        good       are     the       in-
terior          predictions             given        that        the     computer              creates         counter-
parts       of    all       elements           of    the      test?".


In    the       present          tests,        the       propeller             tones       are       much      higher
around          the    propeller             plane        than        near      the       end    caps.            The
transmission                to    the       interior          is      overwhelmingly                   dominated           by
sound       passing          through           the       cylinder            wall.         Because           of    this,
the     tests         are     free      of     problems            introduced              by    the     end       caps.
It    is    evident          that        the      tests       simulate,              in    a realistic              physi-
cal     manner,            the    transmission                of      propeller            noise        into       an     air-
plane       cabin.           The       basic        physical            mechanisms              of     propeller           tone
transmission                are,       in    fact,        being         duplicated              in     the     test.        It




           I Illustrations                   of     tests        and     hardware              based     on       sketches

provided          by       C.M.    Willis,           NASA        Langley         Research             Center.




                                                              -10-
                              ORIGINAL               PAGE      IS
                              OF POOR                QUALITY




                                                                     I
                                                                                J




                                                                     1
                                                                     I

                          Fuselage
                          Model                                 :    :     ."              0.2O3



                                                                                     Propeller



         1.829
                                0.076


                                                              x3 _                            0.868
                                                                                                   !




                                                     0.194               Air        Flow           r


                           1[--_                     ;TI t Tlt
                                                 I
                                                 I
                                             /                                 Duct
                                         /
                                     /

                                                                               1.22




FIGURE      4.    MODEL TEST FACILITY                        [ 1 ]
                 (Dimensions in meters}




                   -11-
      ORIGINAL      PAGE    19
      OF POOR       QUALITY
                                                  0.00081 m (0.032 in.)skin
                                                  1.016 m (40 in.) diameter
                                                  x I. 82 m (72 in.) long
  0.051   m

(2 in.)       "_
                                                               0.00051      m        (0.02      in.)
                                                               stringer,  0.0095   x
                                                               0.011 m (0.375    x 0.44                 in.)


                                  Trim  Lining           &
                                  Insulation



                                             0,, 5O8 R                     20 Â°

                                 f,                                              I



                                                                                0.038
                                              0.279




                                                               0.00081      m (0.032  in.)
                                                               frame,      0.0158  x 0.038 m
                                                                (0.625     x 1.5 in.)  channel,
                                                                   0.2 m (8 in.)             spacing.
                                                                   8 req'd.




              0.00081  m (0.032    in.)   floor  beam,
              0.0158  x 0.038 m (0.625        x 1.5) channel
              1.79 m (70.75   in.)    long



              0.00081   m (0.032      in.)     floor     support      at each        frame



              0.00081   m (0.032      in.)floor,   1.82 m (71.87   in.)  long,
              rivet  to supports,        bolt to skin,  cutout  to clear frames




              FIGURE       5.    FUSELAGE              MODEL   [ 1 ]


                                 -12_-
                                                                             ORIGINAL        PAGE       IS

          f      Stiffener                               -                   OF POOR         QUALITY

     J          f      Clip       for       end         ring           and    support        attachment

                                      E
                                                  ,          _               floor




                                                                                holes       for     screws

                             0


0
                                  i_0i%/                                        tO   skin     and      end         rings


                                  !         :                    O I /--cutout                    to clear         ring      frames
      i
    Ol                            I     i                        L'u
      I
      I                           I     I                        o
                                  I     I
      I                           I     I
      I                           I     i                        o
      I
      I                           I     I                                                                           0.038                    -J
    Ol
      I                                                                                                            0. 00081       -----_--
      I
      I
     I


                                                                                                                                        j
                                  I 01/_
                                                                                     0.0159



                                            i--.-,      floor                                            frame            and   floor        beam
                                                        beam



              cutout     to clear               floor        beam

               0.794                                                                                         _floor


                                  U
                                                                                                                    floor       support
                       0. 495 R




                                                                                                   _                  frame

                                                                                        f
                                                                                                             "_"      skin




                                 FIGURE    6.    FLOOR   ASSEMBLY                                      [ 1 ]
                                     (Dimensions    in meters}
                                                        -13-
ORIGINAL    PAGE   IS
OF   POOR   QUALITY




                                :E
                                m

                                ,.,,,


                                Z


                                "r

                                ,v'

                                m

                                Z
                                    m




                                    >-


                                    L_

                                    L_.

                                    Z
                        E           Â©
                                    u

                                    F--


                            E           I




                                        ,v
                                        (J



                                        L_
                                        e,,




        -14-
is     reasonable,               therefore,                  to     expect          good        predictions              with       PAIN

only      if      good       physical              modeling           has          been     achieved,              i.e.,     with
respect           to       the     coupling             of    the     propeller                 pressure           field     with
the     sidewall             and        sidewall             with     the          trim.         Also        the    sidewall

and      floor         response              must     be      properly              predicted              and     their     cou-
pling        to       the    interior             _acoustic           space          adequately               described.

The     rapid          decay           of    the    pressure              field        away          from     the    propeller
plane        leads          to     the       above          conclusions.


3.1       Test         Configuration



The     test          configuration                 is       shown        in       Figure        4.        The     fuselage
and     propeller                are        located          downstream              of     a    duct        that     supplies
air     to     simulate                airplane             forward        velocity.


3.1.1          Fuselage            2



The      fuselage             (Fig.          5)    is       a cylinder              1.83m        (72       in.)     long     and
 1.02m       (40       in.)        in       diameter.              The     skin        is       0.00081m           (0.032       in.)

thick        and       is    stiffened              by       eighteen              (18)     stringers              spaced       on
20 Â°    centers.                 The        stringers             are90        Â°    angles           having        dimensions

of     approximately                    0.00953          x    0.00953              x 0.00051m              (3/8     x 3/8       x
0.020        in.).           They           are    riveted           to    the       inside           of     the    skin     and
pass      through            cut-outs              In       eight     (8)          internal           ring       frames      that
are     spaced             along        the       cylinder           every          0.2m        (8    in.)         The     frames
are     aluminum             channels              with       dimensionsof                      approximately               0.016
x 0.038           x    0.00081m              (5/8       x    I-I/2        x 0.032           in.).


The     floor          of    the        cylinder             (Fig.        6)       consists           of    a 0.00081m




          2 Most            of     the       descriptive              information                    in    this     section

can     also          be    found           in Appendix              E of          Ref.     I.




                                                                  -15-
(0.032        in.)        plate        stiffened              by supports                 of    the       same          thickness
spaced         every       0.2m        (8 in.).               The       supports           extend          downward                from
the     floor        to    the     bottom           of    the          cylinder.               There       are          also       two
floor      beams          (channels            of    the          same       dimensions              as    the          cylinder

ring      frames)          that        run     longitudinally,                      each        located             approxi-
mately         0.14m       (5.5        in.)       from        the       center        of       the       floor.           The
width      of       the    floor        is     0.848m             (33.4       in.)        leading          to       a    floor

angle  _o of 56.6 degrees   (see Fig.                                         I).    The outer  edge                             of
the floor is bolted   to the cylinder                                          wall.    The cylinder                              is
closed         by    0.013m           (I/2     in.)       thick           end      caps        that       are       used          to
support         the       cylinder           in     the       NASA       Langley           propeller                test          rig.
The     entire         fuselage          assembly                 is    constructed                 of    2024-T3
aluminum.



3. I. 2        Trim


The     end     caps       are        lined       (inside)              with       one     layer          of    0.0127m
(I/2      in.)       thick        Owens-Corning                    PF-I05          Fiberglas              having             a
density         of    9.61        kg/m 3 (0.6             ib/ft 3) with               a O.O0005m                 (0.002

in.)      thick        vinyl          film     facing.                 The    circumference                    (or       side-
wall)      is       lined        with     four       layers             of    the     same          material;                three
layers         between           frames        and       the       fourth          covering              the     frames.
The     unfaced           surface         of      the        fiberglass              insulation                is       exposed
inwardly.             The        finish        trim          is    a     sheet       of    epoxy/fiberglass
material            with     properties              of       a National              Electrical                Manufac-
turers         Association               (NEMA)          G-IO          (equivalent              to       Mil.       Spec.
18177,         GEE).         The       thickness              is       0.00079m           (0.032          in.)          and       its
surface         mass        is    1.465        kg/m 2         (0.3        lb/ft2).              The       trim          is       hard

mounted         to     the       floor        and     attached               to    the     rings          by     nine            soft
mounted         screws           (Fig.        7).        A    120 Â°       sector          of    the       trim          surface
is     covered         with       a    sheet        of       vinyl        (similar             to     automobile                  up-
holstery)            of     the       same     thickness.                    The     total          weight          of       the
trim      is    6.58        kg    (14.51          lb)        with        a surface             area       of     3.624            m2
(39     ft 2) which              averages           out       to       1.815       kg/m 2        (0.371          lb/ft2).




                                                              -16-
The      120Â° sector             of       vinyl       on     the    trim       simulates              a similar            treat-
ment      in    a well-known                   light        aircraft.              Its    presence            introduces
a small         (and       undesirable)                 discontinuity                in     the       surface        weight
of    the      trim       but    benefits              the    test       by    providing              some     damping
of    the      hard       epoxy/fiberglass                    trim.           The    PAIN        model        is    de-
signed         to    include          a    dissipative              trim       lining.


3.1.3          Propeller


The      propeller          is     a three-bladed,                      0.3     scale       Hartzell           for     a
Twin      Otter       aircraft             with        a diameter             of    0.76m        (30     in.).         It

is    driven         by    a 30       kw       (40    horsepower)              variable              speed     electric
motor       capable         of     turning            it     up    to    8000       rpm.         The     propeller
blades         are    Series          16       airfoils.            The       clearance              between        the

blade       tip      and    cylinder              wall       is    1/10       of    the     propeller              diameter
or    0.076m         (3    in.).           In     all       tests       the     blade       pitch        is    fixed        at
20 Â° .


3.2       Description              of      Tests 3


The      primary          tests       of       concern        here       are       those        where        the    interior
noise       was      measured             as    the     propeller             turned        at       different         speeds.
In    the      present          study,          three        speeds          are    considered:                3000,
4000,       and      5000       rpm.           The     airflow          velocity          in     all     three       cases
is    23.8      m/s       (78     ft/sec),             or    about       46    knots.


In    the      propeller           tests,            with     the       model       fuselage           in     place,        the
only      acoustic          measurements                    were    of       the    sound        levels        inside        the
cylinder.             These        were         taken        with       an    array        of    eleven        (11)        micro-




          3 Tests          reported             herein        were       performed              at    NASA     Langley
Research            Center.



                                                             -17-
phones spaced along a cylinder                                               diameter          to       represent  measure-
ments over equal annular   areas                                             (Figure          8).        The array  was
positioned    at four axial     stations,                                            _/L    = 0.125,  0.375,
0.625,    and 0.875,  representing        the                                        center   of four subvolumes
(segments)             of     the      interior.                        At     each of            the       four     axial         sta-
tions,  there were 49 sampled locations obtained    by position-
ing the array  at $ = 0Â°  +51 5Â° and +103 Â°    (Note,
                                                    '
                                                       for all
                                                          i         â€¢                  --



tests,        the      angle           _     in    Figure                 8 was        90 o .            _ and       Â¢ in        Figure
8    are     not      to    be     confused               with            PAIN         0     and        Â¢    of     Figure         2.)
A    total       of    196        measurement                   locations                   were        sampled          from      which

the     space-average                   interior                levels              are      obtained              for     each       har-
moni c.


Supplementary                 tests          were             performed              to      assist           in    diagnostic
work       related          to     the       determination                          (and/or             evaluation)              of     PAIN

input        data      and        intermediate                      output.                 The     PAIN       program           pres-
ently        uses      propeller               noise            predictions                      made        for    a     free     field
condition,             then         applies              a     correction                   to     account           for     the      cylin-
der's        presence.                 This       is          done        because            the        blocked          pressures
are     not      available                 from         present               propeller             noise          prediction

programs            (it      is     the       author's                   understanding                   that       NASA        Langley
has     begun         work        on       this         problem;                PAIN        can     be       easily        modified
to     accept         the     new          type         data            when     available               -    see       Section         3      of
    ef. (2)).

Free        field      measurements                      of      the          propeller             noise          field        were
made        to     compare          against              the            PAIN     propeller               noise          input       data
 created           with      ANOPP.            This            was           done      to     permit          the        determination

of     the       extent       of       "biasing"                 of          interior             noise       predictions                 by
inaccurate                 exterior           noise            predictions                    from          ANOPP.         Figure           9
 shows        the     test        configuration.                              Measurements                   were        made      (with

 the       cylinder          absent)              for         the        three         propeller              speeds         used         in
 the       interior          noise          tests.               The           microphones                  were     positioned
 such       that      predicted               and        measured                   data      along          the     grid        line




                                                                        -18-
                                r/R
                                                             ORIGINAL   PAGE   IS

                                .250                         OF POOR    QUALITY
                  1,9
                  2,10          â€¢433
                  3,11          â€¢559
                  4             â€¢561
                  5             .750
                  6             .829
                  7             .901
                  8             .958
                                                                                  0=90   Â°



                                                                               Â¢ = O, "" 51.5 Â°,   103 Â°




                                                                           R

   ./

_0.752m     OIA
  3 BLADE PROP
  0.076 m TIP
  CLEAP.AN_




 AIR DUCT                                              CYLINDER
 (1.zz =mOIA)                                          (1.02   â€¢ DZA)




                  FIGURE   8.         PROPELLER      TESTS




                                              -19-
             ORIGINAL   PAGE     IS
             OF POOR    QUALITY




                                                      0.868




                            o.o15



        r



                               0.609


/




    FIGURE    9.   FREE    FIELD       MEASUREMENTS
                   (Dimensions        in meters)

                                       -20-
     =I    of     Figure        3    could       be     compared.


A 0.508m           (20       in.)     diameter           hardwood             cylinder              with        flush-

mounted           microphones              in    its     surface             was     used        to    measure
blocked           pressure           levels       along          the        grid     line           I-I     to     de-
termine           the       increase        in    sound          pressure            levels           arising          from
surface           reflections              (the       fact       that        the     hard        cylinder          is
only       one-half           the     diameter           of      the        model        fuselage           is    probably
not       too     serious           a problem           for      measurements                  taken        along        _ =I    ).
The       test     configuration                 is     shown          in    Figure           10.


Finally,           measurements                 were     made          of    acoustic            and       structural

loss       factors.             As    usual       for       these           types        of    measurements,
data       are     spotty,           generally           taken          at    whatever              frequencies

they       could        be    reliably           interpreted                 and     generally              unidenti-
fied       with     respect           to    particular                 modes.


3.3        Measurement               Results


3.3.1           Loss        factors


Acoustic           and       structural           loss        factors              for    the       outfitted            model

fuselage           are       given     in       Table       I.         All    of     the       numbers           are     based
on    reverberation                  decay       times        of       terminated              excitation              tones.
The       decay        of    the     sound       level        inside          the        model        fuselage's

cabin       determined     the acoustic   loss                               factor,  Un"                The  struc-
tural       loss   factors    of the fuselage                                skin and of               the finish

trim       are     given        respectively                by     _        and    _T"         The     loss       factors
are       computed           using     the       relation




                                                       =2.2/fT60



where   f is             the frequency                 of     the      excitation               and       T60    is     the
time  for a              60 dB decay.




                                                              -21-
                ORIGINAL    PAGE     IS
                OF POOR QUALITY




                =0   Â°


                     %(=)


            1     0.508
        Z         O. 102
            3     0.0                                                I             R4
            4    -0.102
            5    -0.508




                            FIGURE        10.   MICROPHONE       LOCATIONS   FOR        BLOCKED
    /                                           PRESSURE      MEASUREMENTS
(




                                                             -22_-
       Table     I.    Measured     Acoustic        and     Structural      Loss      Factors




  Cabin        (Micro.)              Trim     (accel.)             Fuselage        (accel.)
          i




Freq.                                                              Freq.       T60
               T6o     _n         Freq.       _60          "T
(Ez)          sine                (Hz)       trim                  (Hz)       panel
                              |




  93      1.2         0.020         45    0.462       0.105          127      0.30"        0.057

 115      0.61        o.o31         88    0.442       0.056          500      0.041"       0.1o7

 142      0.46        0.033        110    0.091       0.219          890      0.043        0.057

 192      0.27        0.042        170    0.065       0.199         1345      0.031"       0.053

 289      0.40        0.019        216    0.065       0.156         1465      0.o41        0.037

 301      0.21        0.034        290      0.065     0,116         2337      0.047        0.020

 377      0.53        0.011        4O0      0.065     0.085         2710      0.026*       0.031

 452      0.19        0.025        500      o.039     0.113         4225      o.o17"       o.o31
 512      0.33        0.013        650      0.o35     0.097
                                                                    .      ring    and   stringer
 655      0.37        O.OO9        825      0.o42      o.o63
                                                                    *      stringer
 702      0.13        0.024       1oo0      0.o3o      0.o73

 755      0.058       0.050       115o      0.o21      o.o91

 865      0.048       0.053       14o0 0.027           0.058
 932      0.094       0.025       15oo 0.025           0.059
 942      0.078       0.029       18oo o.o14           0.087
1010      0.15        o.o15       2100      0.032         0.015
1260      0.11        0.016       2300      0.015         0.064

1355      0.10        o.o16       2800      0.015         0.052
1700      0.10        o.o13       3400      0.019         0.034

1755      0.04        0.031       4100      0.038         0.014
1770      0.021       0.059       4600      0.023         0.020
1965      0.029       o.o38
2000      0.032       0.034
2OOO      O.O08       0.137

2037      O.018       0.060
2162      0.017       O.O6O
5625      0.089       O.O04
5725      0.034       0.011


                                             -23-
3.3.2      Proweller            noise


The     measured         free       field        propeller              noise         levels        are        shown        in
Figures         11    through         13.        The        data     are       for        the     grid     line    _=I
as    previously            noted      in    Section              3.2.         In     the        figures,        the
plotted         values        are     one-third              octave           band        levels        for     those
bands     in     which        the     propeller              blade        passage           frequencies                and
their     harmonics            lie.         These           are    to     be       considered             the     true
tonal     levels         where        it    is    evident            that          the     tones        clearly

dominate         (for       instance          near          the    propeller               plane).             Broad-
band     noise        appears         to    be    present            in       measurements                at    large
distances            from     the     plane       of        rotation.               Figure         14     shows        a

typical         measured         spectrum.                  Comparison              of     measurements                in
Figure        14 with _ the           data       plotted           in     Figure           13     (Run     No.     8113,

Microphone            I),     shows        that     the       peaks           correspond             to    the     third-
octave        levelsat           least        out       to    the        fourth           harmonic.


Phase     measurements                that       were        made        in    the        4000     and     5000        rpm
cases      are       shown     in     Figures           15 and           16.         The     arrows        indicate

the     approximate            phase        differences                  measured            with        microphone
pairs      (1,3)        and     (2,3)       in    runs         8112       and        8113.


3.3.3         Interior          sound       levels


Sound      pressure           levels        at    the        blade        passage            frequencies               and
their      harmonics            are     given          in    Tables           2,     3,    and     4.      The     interior
measurements             were       analyzed            in     one-third              octave         bands        and        the
band     levels         for     those       bands           containing               the     tones        were     taken           as
the     tonal        levels.          The     first          three        harmonics               were        sufficiently
high     on     the     inside        to     clearly           dominate              the     broad-band            noise

background.              Narrow         band       analyses              of    a     few        records        indicated
that      the    fourth         and     higher          harmonics              were         so    far     down     in        the
noise      that       data      for those              harmonics              were        defective.              Figure           17

shows      a typical            interior           spectrum              illustrating                the        problem          with




                                                            -24-
                                                                                     O? L.:g:,2QU::..Li_Y
    125




    120          _ow e = 1   (x I = 0.457m,      x2    = o.o)
                                                                                                                   BPF = 150 He



t   115
                                                            I_                                   H=I
                                                                                            160        He


    110                                                                                                                          H=I




    105                                    H=I
                             I'1=1


                                                                                          315     He                             2,3


    1DO
                                                                                           5                                 5


                                                                                           2
                                           5
     95
                                           4
                                           3




     9O                                                                                     4




     85                                                                                                                CONFIGURATION


                                                       â€¢   8099                           23.8                        Bare       Nozzle
                                                       â€¢   8102                           23.8                                   "

      8O                                               â€¢   8108                           23.8                                   "
                                                       â€¢   8111                           20.4                        Nose Fairing
                                                       â€¢   8114                           23.8                             "
                                                       _8121                              23.8                                   " w/o     prop.


           !                           I          !              I      I             !                !       l       !               T           I
           1.0                       0.5                                O                                   -0.5                             -1.0

                                     Distance     from      Propeller       Plane,    x3 / Op

                                FIGURE          1"1.       MEASURED            FREE FIELD NOISE -
                                                           PROPELLER            AT 30130 RPM

                                                                 -25-
        125
                    Rote e = 1 (Xl=O.457m,        x2--O-O)                   _              -               _                      BPF=200Hie


                                                                                                                    X=l

        120              ORiGiNAL PAGE _




        115
                         OF POOR     QUALIT_K               _,
                                                            .               Z_
                                                                        2                                                                     H=I

                                                                                      /              3_200          Ibe band             '_

        110


                                             /                          3                                                  ban,,
                                                                                                                    630 Ire       band
        lo5                                                                                                                                              'IF


                                             H = 1                      4                                           800 I_        band
    m



                                                                        5                                           1000   Xm band




                                             /                                                                                                          2


|        95


               -                                                                                                                                    4
                                                                 Run No.         Vc_ (m/s)             Configuration


                                                       â€¢         8100                23.8              Bare Noefle
                                                        â€¢        8103                23.8
         85
                                                        â€¢        8109                23.8
                                                        â€¢        8112                20.4              Nose Fairing
                                                        â€¢        8115                23.8
                                                       â€¢         8122                23.8                           "wto   Prop.
          8O




                    I                I             I             I               I               I              I             l                 I                 I
                   1.0                           0.5                                             0                                        -0.5                 -1.0

                                                   DTstance fT_om P_opeller   Plane,   x3/0 p
                                FIGURE            12.    MEASURED        FREE    FIELD     NOISE-
                                                            PROPELLER                       AT       4000       RPM

                                                                                 -26-
     130
                 Rowe =1(Xl=O. 457m,x2=O.0 )

                                                                                  H= 1        BPF=250He

     125




                                                        _H                            2     H=I
     120




     115




     110


_L

     105




                                                                 Run Ro.       Â¥_ (u/s)     Configuration
      85
                                                             â€¢   8101          23.8         Bare Noezle
                                                             â€¢   8104          23.8             â€¢
                                                             â€¢   8110          23.8             "
                                                             â€¢   8113          20.4         Nose Fairffng
                                                             â€¢   8116          23.8             "
                                                                 8123          23.8                " w/O P_op.



            I          I       !        I        I       I       I         I          I        t         I
           1.0                         0.5                       0                          .,0.5

                                             01stance from Propeller     Plane,    x3/0 p
                                   FIGURE      13.   MEASURED           FREE FIELD  NOISE-
                                                     PROPELLER           AT 5000 RPM
                                                         -27-
                                              O




                                      I           m




                                                  "       ,,, _




                                          -:
                                          I




                                                              m



              q,


m




                                                      N


 m                        v
v



     tl

     a


                                  1


                              m   I
                                              I
          I




                   -29-
                                                                                               o




                                                                                                          N




                                                                                                   "    "|_0




                                                                                                               .<




                    N

v


                                                                                                               ii


m                                            N                                                     N

                                     -       c;                                                    c;

                        II




        L       !        f       f           o                    I        [       1               =
                                                          o   â€¢       0        â€¢       â€¢
    0       0       0        0


                                 I
                                                                                           I
                                         I


                                                                      Q,

                    ,q                            -3(?-
I   !

m




        ed nr _   a.,a _]p '"I3AH'I H'dfl$$H'ddOWIOS
                                 -51-
                                 Table        2.      Interior              Measurements                  -

                                                      3000         RPM,      Harmonic            No.          I (150     Hz) _



                                             Sound         Pressure          Level,         dB       re       20   #Pa



Run                                                                                                                              M
                 x3/R p           _Â°         M I     M 2     M3       M 4     M 5     M 6        M 7          M8   M9     M IO       11
8018             +1.17      -1o3             82      83      85       83      83      83         83           83

      21                    -51.5            83      84      85       86      86      87         87           87    80    80

      24                          o          80      80      80       79      79      *          79           79    81    82

      27                         51.5        78      77      75       73      71      71         70           70    82    82

      30                         1o3         77      77      76       77      77      78         78           79



      14         -.03       -103             76      76      *        78       79     79         *            82

      11                    -51.5            73      73      *        77      79      79         *            81    79    81     *

       8                          0          75      72      71       69      69      69         *            *     â€¢     81     *

       5                         51.5        78      78      79       79       80     79         *            80    â€¢     78     *

       I                         103         80      81      81       82       83     83         *            85



      51         -1.23          -103         78      79      79       80       82     82         82           *

      48                        -51.5        75      74       75      76       77     78         80           81    *     82     83

                                  0          77      76      76       75       74     74         75           75    *     84     86

      42                         51.5        80      81      81       81       82     82         82           83    *     81     82

      33                         103         80      81      82       82       82     83         83           84



      54         -2.43          -103         80      81       82      82       83     83         84           84

      57                        -51.5        81      82       83      84       85     86         86           86    *     81     82

      60                          0          80      80 _     80      79       79     79         79           78    80    82     83

      63                         51.5        79      77       76      75       74     73         72           *     80     81    81
      66                         103         78      78       78      79       79     79         80           80




           160    Hz     Band

*      =     data        judged         to    be     of     poor      quality         and        discarded




                                                                   -32-
              Table    2.        (Continued).          Interior       Measurements                 -
                                 3000   RPM,      Harmonic     No.       2   (300      Hz)*


                                   Sound        Pressure     Level   t dB         re   20 ,Pa


R_.n
             x3/R p      _o        MI    M2       M3   M4     M5     M6      M7        M8     M9       MIO   M11
8018         +1.17     -103        62    65       72   65     64     63      62        60
   21                  -51.5       61    65       66   68     68     69       69       69     67       70    *
   24                       o      48      54     58   6o     57     *        58       57     64       65
   27                      51.5    62      65     67   66     69     67       68       67     60       62    *
   3o                      103     66      70     71   72     7272            73       73


   14        -.03      -103        68    67       *    62     64     62       *        70
   11                  -51.5 61            61     *    61     61     61       *        61     61       61    *
       8                 0   68            68     68   69     69     70       *        *      â€¢        72    *
       5                   51.5 68         66     66   67     66     67       *        67     â€¢        67    *
       I                   I03     69    69       69   68     68     66       *        63


   51        - 1.23    -IO3 52             51     51   51     52     51       51       *
   48                  -51.5 51            51     52   52     52     52       52       52     *        62    62
   45                    o   64            68     69   70     71     71       71       72     *        64    67
   42                      51.5 62       62       62   62     62     62       62       62     *        58    60
   33                      I03 54        54       56   58     64     61       63       65


   54        -2.43     -103        61      61     61   61     61     61       61       61
   57                  -51.5       60      59     64   67     68     69       69       69     *        74    73
   6O                       0      64      72     75   76     78     78       78       79     76       78    79
   63                      51.5    62      65     68   69     71     70       71       *      74       76    77
   66                      103     69      68     68   67     66     66       64       62




       315    Hz    Band




                                                   -33-
                Table         2.     (Concluded).              Interior              Measurements               -

                                     3000     RPM,       Harmonic         No.        3    (450         Hz) _



                                      Sound        Pressure         Level,           dB       re   20    ,Pa



Rw1
              x3/R p           _o     MI      M2     M3       M4     M5      M6           M7       M8     M9        MI 0   MI I
8018          +1.17          -103     50      47     63       45     47         49        50       50

      21                     -51.5    51      50     52       53     52         54        54       54      51       49     *

      24                       0      50      44     44       48     52      *            53       54      52       50     *

      27                      51.5    51      50     50       51     54         53        53       53      51       52     *

      30                      103     52      48     51       53     55         56        57       58



      14      -.03           -103     47      45     *        51     55         55        *        54

      11                     -51.5    51      52     *        54     56         54        *        55      54       53     *
       8                       0      49      45     47       51     52         52        *        *       â€¢        47     *

       5                      51.5    50      45     46       49     53         52        *        53      â€¢        51     *
       I                      103     54      53     52       51     53         55        *        61



      51      -I .23         -103     44      50      54      56     55         58        58       *

      48                     "51.5    46      49      52      54     56         57        57       58      *        55     57
      45                       0      44      42      45      48     50         52        51       52      *        55     55
      42                      51.5    44      50      54      56     59         58        57       57      *        50     54
      33                      103     51      50      51      51     51         51        52       52



      54      -2.43          -103     48      45      48      51     54         55        56       57

      57                     -51.5    51      52      52      52     53         53        56       53      *        52     54
      6o                       0      50      48      46      44     47         49        49       51      51       49     5o
      63                      51.5    48      44      45      48     50         50        51       *       48       49     52
      66                       103    51      48      45      44     47         45        46       47




      * 500    Hz     Band




                                                           -34-
                             Table    3.      Interior            Measurements                 -

                                              4000        RPM,     Harmonic           No.          I (200           Hz)   _



                                     Sound        Pressure         Level,        dB       re       20         uPa



Rtln                          _o     M I     M2      M3      M4     M5      M6        M7           M8          M9    M I0     M II
8019                    -103         87      92      *       94      95     96        96           97

  22                    -51.5        88      91      92      92      93     93        93           93          80    87       91

   25                         0      76      81      84      86      87     *         90           91          71    70       *

  28                         51.5    77      82      84      85      86     85        85           85          86    90       *

  31                         103     87      91      93      93      94     94        94           95



   15        -.03       -103         84      86      *       87      88     87        *            91

   12                   -51.5        87      88      *       90      91     90        *            90          87    90       94

       9                      0      85      86      *       87      87     88        *            89          *     87       *

       6                     51.5    86      83      87      77      74     75        *            *           *     87       91

       3                     103     87      90      92      93      94     94        *            95



   52        -1.23      -103         87      89      89      90 _ 90        89        89           89

  49                    -51.5        87      89      90      91      91     92        92           92          *     89       91

   46                         0      86      87      87      88      89     90        90           91          *     86       85

   43                        51.5    82      76      65      79      83     84        86           87          *     87       87

   34                        103     87      91      *       94      95     96        96           97



   55      â€¢ -2.43          -103     80      83      85      85      85     86        85           85

   58                       -51.5    79      86      88      90      91     91        92           92          84    87       89
   61                         0      82      85      87      88      89     89        90           90          77    78       79
   64                        51.5    85      89      90      92      93     94        94           *           67    74       77
   67                        103     85      90      92      93      94     94        95           96




       200    Hz     Band




                                                                                                         !i
                                                                                                        ,p




                                                          -35-
            Table     3.          (Continued).              Interior          Measurements                   -

                                  4000    RPM,     Harmonic        No.        2    (400         Hz)*



                                    Sound        Pressure        Level,           dB       re   20     .Pa



Run                         _o      MI      M2     M3       M4    M5      M6           M7       M8      M9       MI 0   MI I
           x3/R p
8019       +1.17      -103          62      68     *        78    79      79           81       80

  22                  -51.5         72      75     78       79    79      81           80       81      75       79     76

  25                        0       70      71     71       70    65      *            71       71      74       76     *

  a8                       51.5     64      73     79       82    84      84           85       86      67       74     *

  31                       103      72      73     75       78    79      80           81       81



      15   -.03           -103      73      69     *        69    75      71           *        71

      12                  -51.5     72      75     *        79    79      78           *        69      75       70     65
       9                    0       72      72     *        75    75      77           *        78      *        78

       6                   51.5     74      74     81       77    78      79           *        *       *        78     76
       3                   103      74      70     70       71    73      73           W        79



  52       -I .23         -103      77      77      78      79    78      80           80       80

  49                      -51.5      72     67     76       79    81      82           84       84      *        66     68

  46                        0       76      76     77       77    74      79           77       78      *        81     82

  43                       51.5      75     72      71      73    75      72           74       76      *        82     82

  34                       103      68      70     *        82    82      84           85       86



      55   -2.43          -103       78     78      81      82    84      85           85       85

  58                      -51.5      74     75      81      84    86      86           86       86      85       84     86
  61                        0        77     75      75      75    75      76           76       76      85       84     84
      64                   51.5      77     79      83      85    86      87           87       *       80       80     82
      67                   103       79     77      80      82    82      84           85       85




  * 400     Hz     Band




                                                         -36-
           Table       3.     (Concluded).           Interior          Measurements               -

                              4000   RPM,       Harmonic        No.    3    (600         Hz) _


                               Sound      Pressure      Level,         dB       re   20    _Pa



                      _o       M1    M2     M3     M4      M5     M6        M7       M8     M9        MI 0   MI I
8019                -103       64    62     *      59      62     65        66       67
  22                -51.5      63    62     62     63      65     67        68       68      57       62     65
  25                    0      64    61     56     50      56     *         62       64      59       61     *
  28                   51.5    62    61     60     60      60     60        58       56      63       64     *
  31                   103     59    60     60     61      62     65        67       69


  15     -.03       -103       59    60     *      64      64     64        *        63
  12                -51.5      64    61     *      59      62     62        *        64     68        69     71
   9                    0      69    67     *      66      66     66        *        67     *         66     *
   6                   51.5    67    62     68     69      72     74        *        *      *         56     61
   3                   103     68    67     70     64      65     66        *        72


  52     -I .23    -103        66    64     63     64      66     68        69       69
  49               -51.5       67    67     66 _ 65        65     63        63       63     *         62     61
  46                    0      63    60     58     57      58     61        63       67     *         65     64
  43                   51.5    61    64     67     68      69     70        70       69     *         65     63
  34                   103     61    60     *      57      57     62        65       68


  55     -2.43     -103        65    64     63     62      63     64        64       64
  58                -51.5      66    66     65     64      64     64        65       65     64        64     64
  61                    0      65    64     61     58      57     59        61       62     67        69     68
  64                   51.5    60    57     62     65      67     68        69       *      64        65     64
  67                   103     52    54     51     54      58     62        63       65




   630    Hz    Band




                                                 -37-
                             Table       4-        Interior             Measurements                  -

                                                   5000         RPM,     Harmonic            No.          I     (250    Hz) _



                                     Sound          Pressure             Level,         dB       re       20     _Pa



Run          x3/R p           _o     M I      M 2         M 3     M 4     M 5     M6         M7           M 8     M 9    MIO    M11
8020         +1.17          -103     86        93         97       97      98     98         98           98

   23                       -51.5    92        99     102         101     101   102      103          103         97     101    *

   26                         0      90        94         97       98      98     *      100          100         92      95    *
   29                        51.5    95        97         99      100     101   101      101          101         83      92    *

  32                         103     98       101     103         103     104   103      103          103



   16        -.03           -103     90        *          *       100     102   101          *        102

   13                       -51-5    *         *          *        *       *      *          *            *
   I0                         0      85        91         *        94      95     95         *            95              96

       7                     51.5    94        95         *        95      94     94         *            *               95

       4                     103     99       102     104         105     105     105        *        105



   53        -I .23         -103     80        *          94       96      98      98    100          100

   5O                       -51.5    92        99         99      100     100     101    101          101                102

   47                         0      91        97         99      100     101     101    101          101                 97     98
   44                        51.5    89        85         85       77      81      83        *            *

   35                        103     87        90         *       104     104      *         *            *



   56        -2.43          -103     86        *          94       96      96      97        97           *

   59                       -51.5    93        98     100         102     102     103    103          104         99     102    103

   62                         0      92        97     100         101      *       *         *            *       *        97    97

   65                        51.5    94        96         98       99     100     101    102          102         *        *     89
   68                        103     99       101     104         105     106     106    106          106




       250    Hz     Band




                                                                -38-
           Table       4.     (Continued).             Interior        Measurements              -
                              5000   RPM,       Harmonic        No.    2    (500         Hz)*


                               Sound      Pressure       Level,        dB       re   20    _Pa



                     _o        MI    M2     M3     M4      M5     M6        M7       M8     M9       MI 0   MI I
8020               -103        90    81     77     83      87     90        91       91
  23               -51.5       94    92     92     89      88     87        87       88     89       75     *
  26                    0      93    84     82     91      94     *         97       97     88       81     *
  29                   51.5    94    92     92     91      92     91        92       92     89       79     *
  32                   103     90    81     81     84      87     89        89       89


  16     -.03      -103        86    *      *      87      88     86        *        96
  13               -51.5       *     *      *      *       *      *         *        *
  I0                    O      79    80     *      91      93     94        *        94     *        87     *
   7                   51.5    83    85     *      89      90     91        *        *      *        81     *
   4                   103     80    62     85     83      85     86        *        90


  53     -I .23    -!03        89    *      86     88      89     90        92       90
  50               151.5       91    88     82     84      87     89        90       90     *        90     *
  47                    0      91    88     88     91      92     94        94       94     *        89     89
  44                   51.5    91    92     93     93      94     94        *        *
  35                   103     80    75     *      89      91     *         *        *


  56     -2.43     -103        96    *      74     87      92     94        95       *
  59               -51.5       99    97     95     93      91     90        90       90     95       74     91
  62                    0      99    91     84     96      *      *         *        *      *        82     70
  65                   51.5    99    97     95     93      91     90        88       87     *        *      91
  68                   103     96    87     75     87      92     93        94       94




   500    Hz    Band




                                                 -39-
                Table        4.     (Concluded)           _       Interior             Measurements                  -

                                    5000     RPM,       Harmonic            No.        3    (750         Hz)*



                                     Sound        Pressure          Levell             dB       re   20     _Pa



R_                                                                                                                       M        M 11
             x3/'R   p        $o     MI      M2     M3        M4      M5      M6            M7       M8         M9           I0
8020         +1.17       -IO3        71      64     71        67      69          70        72       71

     23                  -51.5       74      75     73        70      70          70        71       73         73       69

     26                       0      77      75     73        73      76          *         78       79         65       71

     29                      51.5    76      74     71        72      74          75        75       74         59       71

     32                      103     74      71     71        75      77          78        78       78



     16      -.03        -I03        63      *      *         64      66          67        *        70

     13                  -51.5       *       *      *         *       *           *         *        *

     I0                       0      76      73     *         67      72          75        *        78                  75

       7                     51.5    79      76     *         74      77          78        *        *                   64

       4                     103     77      74     74        75      77          79        *        83



     53      -1.23          -103     73      *       72       74      76          78        77       78

     5o                     -51.5    77      72      68       70      75          78        80       80                  63

     47                       0      77      74      70       67      68          70        70       71                  77       78
     44                      51.5    75      69      65       66      71          75        *        *

     35                      103     61      65      *        67      68          *         *        *



     56      -2.43          -I03     71      *       65       64      66          67        68       *

     59                     -51.5    75      73      69       64      68          71        72       72         75       72       74

     62                       0      74      71      68       72      *           *         *        *                   69       72

     65                      51.5    69      67      68       70       71         72        73       73                           71

     68                       103     69     64      65       68       70         71        72       73




     * 800     Hz    Band




                                                          -40-
the       higher     harmonics.


Space-average                sound       pressure          level       (Harmonic            H)


PAIN       predicts          the       interior       space-average                sound         pressure         level

for       each     harmonic.             The    equivalent             measured            interior         space
average          needed       for       comparison,             and    the       standard          deviation          of
the       mean     square         pressure          are    given       below.



                                       S-_H= 10 log(Kp2>              H, t/p 2)


where       the     space-average               mean       square          pressure         for     harmonic          H is

                                                               N
                                  <Pi>s,       t=(
                                                               3

V    is    the     volume         of    the    cylinder            above     theofloor             (or     if    data

for       some     sampled         subvolumes             Vj    are    considered            bad     and        not
used,       the     total         volume       of    all       subvolumes          Vj      used,     i.e.,        V =
_Vj).            N is       the    number       of    subvolumes             with       good       microphone
data.


In    the    present          case



Vj    = O.014LR         2    for       microphones             I through          8,       @ = _I03 Â° , _51.5 Â°,             00
      = O.014LR         2    for       microphones             9 through          11,      $ = 0Â°

      = O.O07LR         2    for       microphones             9 and       10,    $ = _51.5 Â°
      = 0.0225-LR 2           for       microphone             11 when       $ = _51.5 Â°


In    the    relations             above,


                                           2 H    2        10SPLS/10
                                        <Pi>S=Po"


                              SPL_=       Sound      pressure           level       measured          in

                                          subvolume            j, harmonic             H

                             po = reference            pressure         =2x10-5nt/m2(20_Pa).


                                                          -41-
 The standard             deviation           of        the       mean square             pressure          is     defined
 by
                                                        N
                              SH=I(                  2 H
                                       I/N- I)_(<Pi>j-<Pi                         2H
                                                                                   >s, t )2_
                                                    j=1

 Since  the sampled   subvolumes                           Vj are not identical   the                              mean
 and standard   deviation   are                          calculated  in the following

â€¢ manners.          Let


                              _=(     I0 sPLH/IO.             Vj- IO-6)/LR           2



 Define        RH    as   the       average         over          N    subvolumes           of   XHJ


                                                   N                          N       N


                                              j=1                          j=1 j-1

 Also     let       the   primed        quantity              be       defined


                                                                  a ,
 where     V    is    the     average         subvolume's                   volume
                                                              N


                                                            J=l

 Then     the       measured         mean     sound            pressure             level    (average            in    space)
  for    harmonic         H    is    given         by       the       exact       result



                                     S_H=60+1OlÂ°g                     RH      "


  The    standard         deviation           is        defined            and      computed      with

                                                        N


                                                        J=1

  The    above       is   a    sufficiently                   close        approximation               to    the      true
  sample        standard        deviation.

                                                                                           URIGINAL PAGE IS
                                                               -42-                        OF POOR QUALITY
Finally,           set


                                                                            .

The     (I-a)%            confidence             intervals             of       the   space            average          sound

pressure           level        at       harmonic          H    are    computed             by    using           xH    and       sH:



                         SPLI"a=60+             101og(EH+sHtm;a/2/_                           )


                                     \



where  tin;a/2   is                  the a/2   percentage                         point  of the                   Student
t - distribution                     with m = N-I degrees                         of freedom.                     In the

present           case,        a value          of    a        equal     to      0.01       is     selected             and
the     99%       confidence              limits          computed.


Figures           18,     19,    and       20    show          the    axial       variations                 of    the
average           sound        pressure          levels          in     the      four       major         (axial)
subvolumes              sampled.            Note          that       very       little        axial          variation
is    present,            however,           the      third          harmonics             of _ the      4000          and
5000     rpm       cases        do       have    a    slightly           apparent             peak       near          the"

propeller              plane.


Table        5    summarizes              the    reduced             interior          noise           levels.              Fig-
ure     21       gives     the       same       results          in     graphical             form.           It       is    the
basic        plot       upon     which          the       PAIN       predictions              can       be    directly
overlaid.



3.4      Com_uter              Simulation             of       Scale-Model             Tests


This     section           begins          with       a brief           discussion                of    some       of       the
details           of     the    modeling             of    the       fuselage           and       trim.           Next        the
propeller              modeling           requirements                 are      considered.                  Then        the
ANOPP        propeller           noise          predictions              used         as    input         data         to     the
PAIN     program           are       scrutinized.




                                                                -43-
                                         ORIGINAL     PAGE lg
                                         OF POOR      QUALITY



                                                    99_         Confidence              Limits




     95      B




     9O
                   Subvolume         1        Subvolm,,e        2                   Subvolu,,,e       3     Subvolume        4


_,   8s-


                                         -'----           _--                   _     ....                              H=       1
     80
=
 A



==   7s

                                                                                                                        H        z

N    7o
                                             o.                                                       /




     55
                          â€¢              I l,
                                                                ........... --.--                                       H=3
      5tl



     45



                  e/t     = O. 125                  O. 375                                   O. 625             O.875

                 x3/R p      1.17                 -0.03                                      -1.23              -Z.43

            FIGURE         18.      AXIAL   VARIATION               OF AVERAGE                    SOUND  PRESSURE
                                    LEVEL   BY MAJOR                SUBVOLUME                    (3000 RPM)




                                                      -44-
                                                         ORIGINAL       PAGE 14
                                                         OF POOR        QUALITY,



                                                         99% Confidence     Limits


     100

                  Subvolme       1            Subvolul          2         Subvoltme.     3       Subvolume      4

     95



     90                                                                                                      H=I



R    85
                                                                                                             1t=2


=t
      8o



_     7S


_-    70                        \\\
|
                                                                                                             H=3
_     65




      55



                          I               I          I              I                !       I           I
            e/L     =   0.125                     0.375                        0.625                 0.875

           x3/R p =     1.17                     -0.03                        -1.23                 -Z.43


           FIGURE        19.          AXIAL  VARIATION           OF AVERAGE   SOUND
                                      PRESSURE    LEVEL         BY MAJOR   SUBVOLUME             (4000   RPM)




                                                         -45-
                                                OF POOR       Qtjl_,Lfi_




                                          99Z Confidence         Limits




     105



     100



      95




== 85
 a




=_
                                                                                           I
_-   75

|
      70
      65
                 Subvol mm 1          Subvol _     2               Subvol cme 3                  Subvol ume 4


      6O



                       I         I         I              I                  I             I           I
           e/L   =   0.125               0.375                             0.625                    0.875

          x3/9 p =   1.17               -0.03                          -1.23                        -2.43


           FIGURE     20.    AXIAL   VARIATION          OF AVERAGE                 SOUND       PRESSURE
                             LEVEL   BY MAJOR          SUBVOLUME              (5000rpm)




                                                 -46-
     Table    5.     Measured         Space     Average        Sound     Pressure           Levels,

                     Entire      Cabin        Space      (Above     Floor)




    RPM _          Harmonic,      H             Freq.        (Hz)            SPL H              SPL


3O00                     I                        150                         81.0           80.2-81.7

                        2                         300                         69. I          67.1-70.4

                        3                         450                         52.9           51.8-53.8



4000                     I                        200                         90.3           89.3-91.0

                        2                         400                         80.3           79.1-81.1

                        3                         600                         65.2           64.2-65.9



5OOO                     I                        250                        IO0.2            99 â€¢ 3- 100.9

                        2                         500                         91.5           90.3-92.4

                        3                         750                         74.0           72.9-74.9



*      calculated       mean

       99%   confidence         that     true     mean       lies   in   this        band




                                                      -47-
                                                                               ORIGINAL                    PAGE                iS
                                                                               OF POOR                     QUALITY




                                                                                                                                    â€¢           SPACE AVEPJ_GE AT                               HAIPlONIC          H
        105    -
                                                                /                                                                                               CONFIDENCE                  LIMITS
                                                                                                                                                99%

        100    --

                                                       /                               _o
                                                                                                                                                    /
         95    -
                                                                                                                                            /
 q                                 \               /
         90    -
                                                                                                                           /                            \
 ==                                         /          \.,..                                                                                                \
                                                                                                                                                                    \
==
         85    -                                                                                                                                                        \
                                       /                                       \                               /                                                                \
Eli
                                                                                       \                   /                                                                        \
=l"
ELI
                                                                                                                                                                                            \
         80    --                                                                                                                                                                                \
ELi
                                                                                               /           \                                                                                         \
                              //
Â¢Â¢
                                           \,_,,                                                                                                                                                          \
                                                                                           /                       \                                                                                           \           /
t,a,l                                                                                                                  \
e,e
eL
         75    --                                                                      /                                   \
Â¢=                                                     \                           /                                                \
=Â¢
                                                           \                   /                                                            \
V)
         70        -                                                \7                                                                              ,,\                                     .>/
                                                                                                                                                                                        /
                                                                                                                                                                \               /
         65        -                                        /                      \
                                                                                       \                                                                        /               \
                                                                                           \                                                                /                       \
          60        .                                                                          \                                                        /                                   N
                                                                                                   \                                            /
                                                                                                       \                                /
          55        _                                                                                          \               /


          50        _
                                                                                                           /                       \

                         I         I               I       )              I                t           !               i                I                   I               !               !             I            I        1
                        100                     200                      300                       400                              500                                 600                              700                   800




                                                                                               FREQUENCY,                      H_




                                       FIGURE              21 . MEASURED                               SOUND   LEVELS  INSIDE                                                               MODEL
                                                                FUSELAGE                               INDUCED   BY PROPELLER


                                                                                                               -48-
3.4.1           Fuselage              modeling


The     scale         model           fuselage                is    basically              the      same       as     the       analyti-
cal    model,          having              ring          frames          and       stringers             on    the        shell       and
longitudinal                 and          transverse                floor          beams       as     stiffeners.                  As

part     of      the       input           data          file       for       the    program             MRP,        there        are
four     quantities                   to       be    specified                that       are     used         in     the     calcula-
tion     of      the       modes           of       the       stiffened             shell        and      which           define        the

characteristics                       of       the       stiffeners:                 Dxs,        the      bending           rigidity
of    the       shell        stringers                   divided             by    the     stringer             spacing;           DR0       ,
the     bending            rigidity                 of    the       shell          frames        divided             by    the     frame

spacing;             Dxp,        the       bending             rigidity             of     the      longitudinal                  floor
beams   divided  by the floor                                      beam spacing;                 Dyp,   the           bending
rigidity    of the transverse                                      floor supports                  divided            by the

support          spacing.                  The       procedure                to    be     followed             to    calculate
these       quantities                    is:        I)        compute             the     moment         of       inertia         of    a
single          stiffener                 about          the       inner          surface        of      the       shell        (or
lower       surface              of       the       fleer),             2)        multiply          by    the        elastic
modulus,             and     3)           divide          by       the       stiffener           spacing.                 The     calcu-
lation          of    the        moment             of    inertia             of    a transverse                   floor        beam

(support)             requires                 special             attention.


Figures          5 and           6    show          that       the       transverse              floor          beams        (supports)
extend          from        the       bottom             of    the       floor        down       to      the       shell        frames

where       they        are          attached.                 It       is    assumed          that       about           0.038m
(1.5     in.)         of     the          total          depth          of    the     support            actually            provides
bending          rigidity                 to    the       floor.              This       is    arbitrarily                 chosen
sincethe              longitudinal                       floor          beams       are       themselves              0.038m           (1.5
in.)     deep         and        because             part          of    the       floor       support             provides            stiff-
ening       to       the     shell             since          it    is       attached          to     the       frame.            This       is
admittedly              an       unknown             complicating                    factor         in     the       test       which        is
assumed          not        to       be    serious,                as    the       upper       part       of       the     shell        is
felt     not         likely           to       be    overly             restrained             by     the       actual          supports
            !




                                                                        -49-
as    compared           to      their        assumed           (computer)                 configuration.


The     input         data       for     the    model           fuselage              (required           by      programs
MRP     and      MRPMOD)          are     given          in     Table        6.        In       addition          to       the
data     shown,the               floor        must        be    specified              (alphamerically)                         as
being       rigidly           connected             to     the       shell.


Also     given         in     Table       6    are        the    input           data       for       programs             CYL2D
and    PAIN.           In     the      latter         case,          the     table          is    used       to     specify
sources          or    models          used.          For       instance,              no       measurements                were
made     of      the     structural             loss           factors           of    the       bare     fuselage

(i.e.,        without            trim),        so     a    simple           model          was    assumed           (_r=2/fr).
The     measured            values        of W r          with       trim        installed,              i.e.,         _        are
given       in     Table         I and        since        PAIN        computes             the       loss      factors
with     the       trim       installed,              a    comparison                 of    predictions                with
measurements                is    possible            and       will        be    presented              later.             The
acoustic           loss       factors          are        taken        as    zero          to    force       PAIN          to

compute          them.


The     trim       panel         mass     per       unit        of     area       has       two       values        shown.
The     first         corresponds              to     the       total        mass          of    the     trim       divided
by    the     surface            area     (including                 as     part       of       the    mass,        the         120 o
sector        of      vinyl)        amd       the     second           the       mass       per       unit     of      area
locally          where        the      propeller               blade        tip       passes          nearest          the
structure             and     where       the       most        intense           exterior              sound       is      real-
ized.         The      latter          value        is     selected              as    the       more     correct               one

to    use     although            either        value           leads        to       approximately                 the         same
final       result.              The     trim       loss        factor           is     set      to    0.13       which          is

the     average   value    of the measured                                  WT (trim  installed)                       over
the     frequency    range   of interest.                                   The properties    of                    the fiber-
glass       insulation              are       those        in     Figure          A-2       of    Appendix             A in
Ref.     (I).          Finally,           the        cavity          length           is    slightly            larger           than
the     shell's         because           of    the        construction.




                                                                -50-
               Table      6.    Input    Data Used To Simulate
                                Scale    Model Tests


    Pro gram                   Description                          Input     Value


    MRP            DxS ,       bending     rigidity        of       62.35     nt-m
                               shell   stringers          di-
                               vided by stringer
                               spacing
                                                                    1.20xiO    4       nt-m
                   _e'         bending    rigidity  of
                               shell   frames divided
                               by frame spacing
                                                                    8.63x103           nt-m
                   Dx_,        bending      rigidity       of
                               longitudinal          floor
                               beams divided           by
                               beam spacing
                               bending    rigidity         of       5.42xi03           nt-m
                               transverse       floor
                               supports     divided        by
                               support    spacing
                   t s,        equivalent       skin      thick-    0.001153           m
                               mess of shell            (includ-
                               ing smeared-out             stiff-
                               ener areas)

                   tp,         equivalent     thickness             0.00127        m
                               of floor    (including
                               smeared-out     stiffener
                               areas)

MRP, MRPMOD        ms_         shell  mass per unit                 3.113     kg/m 2
                               area including   smeared-
                               out stiffener  masses

                               floor  mass per unit                 3. +6 kg/m2
                   mp,
                               area  including  smeared-
                               out stiffener   masses

MRP, MRPMOD        a_          radius     of    shell               0.508      m
PAIN
                   L,          length      of    shell               I.803     m

MRP, MRPMOD        eo,         floor     angle                      56.6 Â°
CYL2D, PAIN




                                          -51-
    Table   6.        (Continued).             Input     Data     Used    To    Simulate
                      Scale     Model      Tests




 Pro gram                     Description                                  Input     Value



PAIN                          structural     loss   factors                2/f
                 Wr_
                              of bare    fuselage    (assure-                    r
                              ing  a mode    exists    at the
                              resonance     frequency,   fr )
                              acoustic    loss         factors     of      0.0
                              bare   fuselage


                 roT,         trim     panel    mass     per     unit      1.82 kg/m 2
                              area                                        (I._6)
                 WT,          trim     loss    factor                      0.13

                 L c,         cavity      length                           I.829     m

                                                                           O. 962    m
                 rp,          propeller        radial     location
                                                                          0.662      m
                 Zp,          propeller        axial     location
                       ,      propeller        circumferential             9oo
                              location

                 B,           number      of   blades                      3
                 Direction    of rotation
                 (counter-clockwise,      looking                  aft)    +I




                                           -52-
3.4.2         P roweller               modeling


The     propeller             is       located       radially             and     relative            to    the       front

of the structure                    by rp and Zp (see Figures   I and 2).    The
circumferential                    position  is given by $ (Figure   2).  Table                                              6
shows     the       values             corresponding             to       those       of    the       test.           The

direction           of    propeller                rotation         is     defined          as    counter-clock-
wise     because          the          top    half      of    the     cylinder             is    swept          by    the
blade     tip       before             the    bottom         half     (or       floor).


The     grid     (Figure               3)    is    positioned             by    placing          the       propeller

at k=8.        In        the       present          test      rig,        each       grid       point       (k,L)
lying     in    the       fuselage                surface       has        coordinates                defined          by
the     equivalence                relation



                              (k,_')           (xl/ ,X2,X
                                                       .t k3)



where     (in       meters)            :




                                                                                        ,
and


                              _3=O.622-0.089(k-I)



This     grid       covers             all    of    the      upper        quarter          surface          of       the    cylin-
der     forward          of     the         propeller         and     a    somewhat             greater          surface          area
behind        it.



Because        of    the       lengthy             calculations                involved          in     the      propeller
noise     prediction                   programs,          the   data           for    the       lower       quarter          of
the     cylinder          seen          by    the    propeller             are       obtained           from         the    data

for     the    top       quarter             with    the      relation            (imagining               an    identical




                                                              -53-
     grid      below     the        centerline)                     ORIGINAL PAC.._ '/i
                                                                    OF POOR QUALF: _


                         ,__,_,_,_=__,-_,_- _                                                     ,
     where      TkÂ£     is    a     time       delay      given     in     milliseconds                 by    the   result


                                          Tkj=333.33akz/N                  â€¢


     N   is    the     propeller              rpm     and ak#      is     in     degrees          and    is     given    by
     the      result
-\




     The      propeller            harmonic           amplitudes          at     corresponding                points
     above       and    below           the     centerline          are       given      by




     and      the     corresponding                  phases     (in     degrees)            are       related       by




                                              o               ovo
     where       TI =       BPF -I       is     in    milliseconds              and    H    is    the     harmonic
     index.           This        can    also        be   written        as


                                    _Hk_ Ibelow=_HkL[             above+2BHak#

     where       B is        the    number           of   propeller            blades.


      Conversion             to    the        coordinate        system          used       in    Figures         I and    2
     is       with    the     relations

                                                 zk=Zp-_3




                                                              -54-
                                                                               ORIGI_AL              PAC_        ;7
and        (using           @ = _/2            in      Fig.       2)           OF     POOR       QUALITY..



                                 _=_12*tan.-II-X_rp--__ i_I}= Â¢+(_-I)-_118                                                  .

The        coordinates                   of    the       grid       point           (k,_)        are        given               by    the
equivalence                  statement

                                     i




                                                          ~ (a,el,zk)                       .

The        selected              grid         has      spacing           A of        0.089m            (3.5           in.).            This

spacing            is       sufficiently                    close        to    assure            a    relatively                      smooth

change            in    phase            for     each         propeller              harmonic               from           grid        point-
to-point.



The        free        field        propeller                 noise       predictions                     needed                at    the

grid        points           were         made        with        NASA        _NOPP         (8).            The        predictions

for        the     3000,           4000,         and      _OO          rpm     cases         were           computed                  at    NASA

Langley            and       provided               to      the     contractor.                      As     required                  for

PAIN        input,           the         predictions                are       the     Fourier               representations
of     the        actual           pressure              time       histories               (the          first             10       harmon-

ics        are     used).            Section              3.4       of    Ref.        (I)        should               be        consulted

for        an     expanded               discussion               of     the     input           model.                As        stated

previously,                  after            being       read-in,             the     free           field            pressure

amplitudes                  of     the        various          harmonics              are        increased                  in        propor-
tion        to     the       incidence                angle         7 (Figure               2)       to     simulate                  the

blocked            pressures.                    The      phases          computed               with        the           propeller
program            are       not         modified.



Creation               of    the         input        data        with        the     propeller                  noise               program

is     a    separate               problem            not      of      concern         in        this        report.                  However

the        quality           of     the        predictions                made        with           that        program               is      of

concern            due       to     the        potential               for     introducing                   bias               errors        in

PAIN        predictions.                       Appendix             E of       Ref.         (I)presents                          a    basic

overview               of    the         requirements                  for     input         data           to        the        ANOPP         pro-

gram        and        it    should            be     consulted               for     any        further               basic           informa-




                                                                  -55-
tion.          Appendix              B    of       Ref.       (I)        deals        with     propeller                 noise

theory         and       should           be       referred              to    if     a more           in-depth            treat-

ment     of       propeller               noise           predictions                 is     desired.



In     the     present           tests,              the      data        used        to     define          the     particular

geometrical                characteristics                          of    the       propeller               are     proprietary
and     thus        are       not        included.                  It    is       simply      noted           here        that        the

angle        of     attack,              chord,           and       blade          thickness            are       specified             as

a    function            of     the       distance                out     along        the     pitch           change        axis

via     a data           list        which           is      then        interpolated                  as    required             to
fix     these        variables                  at      all       locations            on     the       blade.



Figure         22     shows          (for          an     example)             a    typical            predicted            pressure

time     history              and        the       corresponding                    PAIN      model          used.          The        par-

ticular           case        shown,        from          the       5000       rpm     run,        is       the     pressure             at
grid     location               _,_)           =     (7,1).              It    represents               only        one     of     160

such     time        histories                 in       the       PAIN        input        data        file.



3.4.3          Propeller                 noise          predictions                 and      comparisons



There         are     two       fundamental                   questions               concerning               the        exterior

pressure             field       that           have         to     be     answered           before           comparison                of

interior            predictions                    should           be     attempted.                  First,         are     the

free         field       propeller                 noise          predictions                made       with        ANOPP         rea-

sonable,            when        compared                to    the        measurement                results           of    Section

3.3.2?            Also,         are       the        predicted                blocked         pressures               correct?

Equation             (43)       of       Ref.        (I)      is     the       PAIN        model        used        to     adjust

free         field       pressures                 to     blocked             pressures.                Is     it     a    good

representation?



To     answer         the       first           question,                consider            the       propeller            noise
predictions                in    Tables              7,      8,     and       9.      Results            for       the     grid

line     _=       I are       given         (first            5 harmonics                  only,         although            10    har-
monics         are       available).                      The       sound          levels         in     these        tables           are




                                                                    -56-
                                                                 OF POOR            QUA_.i"_ _'




                                                                                                       <


                                          =.

                                                                                                       Z
                                                                                                       <
                                          O

                                                                                                       l,V

           |                              =                                                            -I-

                                                                                                       l-
                                                                                                       e,
                                                                                                       Z
    in                                                                                                 .<
i',,,,     I,--                           I",,,,,
           V'I                                                                                         uJ
  II       mle
           l,lll
m          u.. I,I.I
       m         ,,,.,I        u_
                               m...
           I,--
                                X
â€¢""        II.                 .41                                                                     ZP
0-=                            II
                 ==                                                     eL
Z          =I= i,l.
IC         l..,a                                                                                          Z
,-=                                                                      I                             _uJ
=_
ELI
I"         EL-                                                          II Â¸                           D_
                  ==
                  l,,l=l                                                     .=


                                                                                                        .'JLu
                                                                                                        ,<_



                                                                                                        p.u.


                                                                                                        P,8

                                                                                                        LU

                                                                                                        D




                           I          I             I       I       I              I        I      I

                                                                                  =.              04
                                                            I       I               I       I      I




                                                    (Â¥d) _lrlSS3"dd 11W13AO




                                                                  -57-
                                        ORI_AL            pAGE _S
                                        OF POOR           QUALITY

Table   7.     ANOPP       Predictions            of      Propeller         Noise,       Grid        Line    2 =
               0.762       m Dia.,      3   Bladed          Hartzell         Propeller           @    3000    rpm


                       Sound       Pressure          Level,      dB    re    20 #Pa
Harmonic
    H          k=1             2            3              4           5             6               7         8

    I          90. I        95-5       1OO.5             106.3    112.1         117.4           120.2        114.9

    2          57.0         66.2        74.9              85.1        95.6      105.5           112.5        108.3

    3          24.2         37.0        49.2              63.9        78.9       93.5           104.8        101.9
    4          -8.1            7.8      23.6         â€¢    42.6        62.3       81.5            97.0         95.8
    5           5.3         10.8        16.7              27.5        46.7       69.7            89.4         90.0

                                   Phase,       _H       (degrees)

    I        -148.1       -151.2     -153.6          -155.8      -157.4       -158.0       -153.9            -86.1
    2        -144.2       -148.3     -151.4          -154.4      -156.8       -158.3       -155.7            -92.1
    3        -146.1       -147.1     -149.4          -152.6      -155.8       -158.1       -156.7            -97.7
    4        -142.3       -142.5     -145.6          -150.0      -!54.2       -157.6       -157.4           -103.3

    5        -148.5       -151.4     -152.9          -152.3      -153.5        -157.2      -158.0           -108.7

                       Sound       Pressure          Level,      dB    re    20 NPa
Harmonic
    H          k=9          10          11                12          13         14              15            16

    I         119.3        116.0       110.6             104.8        99. I      94.2            89.0         84.3
    2         110.4        102.9        92.8              82.3        72. I      63.5            54.4         46.3

    3         101.5         89.7        74.9              59.9        45.3       33.0            20.3           9.0
    4          92.6         76.5        57.1              37.4        i8.5           2.8        -12.8        -24.8

    5          83.7         63.5        40.9              23.8        14.8           9.5             4.2        -.5

                                   Phase,       $H       (degrees)
        i




    I         -27.6        -24.1       -24.8             -26.5       -28.7      -30.8           -33.1        -35.3
    2         -28.5        -25.8       -27.4             -30.2       -33.5      -36.8           -40.7        -44.5
    3         -29.6        -27.6       -30.0             -33.4       -36.8      -39.0           -39.0        -33.5
    4         -31.    I    -29.8       -33.3             -37.9       -42.5      -45.3           -42.9        -31.3
    5         -33.0        -31.8       -34.1             -31.4       -29.3      -30.5           -32.7        -34.9




                                                     -58-
                                                                  ORIGIh_'AL PAGE |9
                                                                  OF POOR QUALITY

Table     8.     ANOPP     Predictions                of    Propeller            Noise,       Grid        Line       _=       I

                 0.762     m        Dia.,     3 Bladed           Hartzell         Propeller           @       4000    rpm


                         Soured         Pressure          Level,     dB    re     20 NPa
Harmoni    c
    H            k=1                2            3           4             5              6               7               8

    I            97.6      102.5             107.2         112.6       118.1         123.1           125.7           120.6
    2            68.5              76.4       84.O          93.2       102.8         112.0           118.6           114.4

    3            39.3              50.2       60.8          73.7          87.4       100.9           111.3           108.4
    4             10.6             24.1       37.5          54.2          72.0        89.7           104.1           102.7

    5             12.9             18.5       25.1          37.9          57.2        78.7            96.9             97.2
                               i




                                        Phase,       _H    (degrees)

    I          -139.5     -144.9            -148.8        -152.5     -155.2        -156.4       -152.7               -86.0
    2          -128.9     -138.1            -144.4        -149.8     -153.9        -156.5       -154.5               -92.8
    3          -121.6     -133.1            -140.6        -147.1     -152.2        -155.9       -155.6               -98.8
    4          -111.5     -126.3            -135.6        -143.5     -149.9        -155.0       -456.1            -104.5
    5          -139.2     -143.4            -144.6-144.4             -148.3        -154.0       -156.5 -11o.o

Harmonic                 Soured         Pressure          Level,     dB     re    20 _Pa

    H            k=9               10          11            12           13          14              15               16

    1           124.9       121.8            116.8         111.5       106.4         102.1            97.8             93.9
    2           116.5       109.5            100.2          90.7          81.8        74.6            67.5             61.2
    3           108. I             97. I      83.5           69.9         57.2        47.2            37.5             29.2
    4            99.7              84.8       66.9          49.2          32.7        19.9                7.7          -2.3
    5            91.3              72.6       51.3          33.4          23.0         17.7           13.o                9.1

                                        Phase,       SH    (degrees)

    I           -29.3      -26.1             -27.2         -29.1       -31.0         -32.2           -32.6           -31.6
    2           -31.0      -29.1             -31.7         -35.5       -39.1         -41.2           -41.0           -37.1
    3           -32.8      -31.9             -35.9         -41.0       -46.1         -48.7           -46.6           -37.3
    4           -35.0      -35.1             -40.4         -47.4       -54.6         -58.9           -56.2           -42.8
    5           -37.6      -38.2             -43.0         -42.0       -35.7         -33.4           -32.6           -31.2




                                                      -59-
Table    9.     ANOPP     Predictions              of    Propeller            Noise,       Grid       Line        2=       I

                0.762     m     Dia.,     3 Bladed             Hartzell        Propeller          @       5000     rpm


                        Sound       Pressure           Level,      dB    re    20 HPa
Harmonic

   H            k= 1            2            3             4             5             6              7                8
                                                                                                                           |




    I          104.5       108.9         113.1          118.1       123.2         127.8           130.2           125.5
    2           80.1          86.9        93.5          101.4       109.9         118.1           123.9           120.0

                56.1          65.2        73.9            84.7          96.4      108.2           117.4           114.6
    3
    4           32.6          43.8        54.6            68. I         82.9       98.3           110.9           109.4

    5           18.4          27.2        37.9            52.4          69.7       88.4           104.5           104.5


                                    Phase,        SH    (degrees)

    I         -126.7     -135.2         -141.5         -147.1      -151.4        -153.7      -150.4               -85.1
    2          -98.2     -116.6         -129.5         -140.4      -148.1        -152.8      -152.0               -93.4
    3          -68.6      -98.1         -118.2         -134.4      -145.2        -151.9       -153.1             -100.1
    4          -37.6      -78.7         -106.6         -128.4      -142.1        -150.6       -153.7             -106.2
    5         -110.1     -101.7         -109.5         -125.6      -139.4        -149.2       -153.9             -111.8

Harmonic                Sound       Pressure           Level,      dB     re    20 HPa

    E-          k=9           10           11             12            13          14             15               16
                                              i




    I          129.7       127.0         122.5           117.9       113.5        109.9           106.2           102.8

    2          121.9       115.8         107.8           100.0          92.9        87.1           81.3            75.9

    3          114.2       104.6          93. I           82. I         72.4        64.8           56.9            49.6

    4          106.6          93-5         78.3           64.3          52.2        42.6           32.6             23.3

    5           98.9          82.4         64.0           48.0          36.4        29. I          23.0             18.3

                                     Phase,       SH     (degrees)

    I          -31.0       -27.8         -28.5           -29.2       -28.7        -26.7           -22.5           -16.1
    2          -34.4       -32.9         -35.3           -36.7       -34.4        -28.1           -16.0                0.8
    3          -37.1       -37.3         -41.8           -44.2       -39.8        -28.5            -7.8             19.5
    4          -40.2       -41.9         -48.7           -52.6       -46.3        -29.8            -0.3             38.0
    5          -43.7       -46.4         -54.3           -55.4       -42.5        -27.5           -16.5           -11.1




                                                  -60-
plotted           in     Figures           23,     24,       and       25    against         the       measurements                 of
Figures           11,     12,        and    13.


In     general           it    can     be       stated        that          the     comparison               is    good      for

the     first          three        harmonics,               certainly              near     the       propeller             plane
where        the       tones         rise       well     above          the       broad-band             noise.            Al-

though         the       measurement               and       grid       (prediction)                  positions            do     not
correspond               precisely,              it     is    observed              that,        at    least         in    the
4000     and        5000       rpm     cases,           within          0.25m        (     10 in.)           either        side
of     the    propeller               plane,          the     predictions                  are    quite           good.
There        is     some       indication               that       the       propeller            noise           predictions

might        exceed           the     actual          levels           either        side        of    the        propeller
plane.            This        cannot        be     confirmed                because         measurements                  were
not     made        at    those        locations.



The     phase          predictions               (given           in    the       tables)         are        plotted         in
Figures           26,     27,       and     28.        Measurements                  are     available               for     com-

parison           in     the    4000        and       5000        rpm       cases.          The       phase        itself
cannot        be       compared,            but       the     phase          difference               _mm'           between
grid     points           m    and     m'.        This        is       the    quantity            required            when
calculating               the       modal        forces           (see       Eq.     (41)        of    Ref.        (I)).          In
Figures           27     and    28,        the    predicted                 phase       differences                are     indi-

cated        between           those        positions              (along           grid     line       2=    I) where            the
microphones               were        located          in     Runs          8112     (4000        rpm        case)        and
8113     (5000           rpm    case)           which        produced             the    phase         measurements                of

Figures           15     and     16.        As     can       be    seen       the       calculated                phase      dif-
ferences           and        the     measured           phase          differences               compare            quite
well     for       the        first        three       harmonics              (within            10    to     15     degrees
usually).



In    summary,            it    can        be    stated           that       ANOPP       certainly                does     a good
job     of    predicting               the       exterior              field.           '_/hile there              are     indica-

tions        that        the    levels           may     be       over-predicted                  slightly            in     the
regions           just        fore     and       aft     of       the       propeller            plane,           there     is     no




                                                              -61-
     130    -


                                                      ORIGINAL PAGE Ig
                                                      OF POOR QUALITY
     125




     120




     115



                                                                8zo2
     110

                                                                                  H=2


'-   105


                             8099                                     H=3
.3

_    100




_     9s




       85




                I     I         I     !      I         !          I           !
            1.0                      0.5                         0
                                      Disl_nce   f_    P_pel]er        Plane,       x3/D p

                    FIGURE     23.   COMPARISON            OF   PROPELLER               NOISE   PREDICTIONS
                                     AND   MEASUREMENTS,                    3000 RPM

                                                      -62-
                                                          ORIGINAL   P_.tg_ |_
       130                                                OF POOR    QUALITY




       125




                                                                             . = I (zoo .,1)
       120
                                                          8103




       115

                                                                      H=2


                                                             H   3
                                                                                             8115
=,
                            8100


                                                             11=5
=      zo5
   a




_..1




|
        95




        9O




        85


                                                                                                       e=Z

         8O                                                                      â€¢    Composite of Pleasurements
                                                                                      (Runs 8100, 8103, 8115)
                                                                                 â€¢    MOPP Predictions




             1.0                    0.5                      0                        -0.5                   -1.0

                                   DISTANCEIRON PROPELLERPI.NIE,     X3/Dp
                   FIGURE   24.    COMPARISON  OF PROPELLER    NOISE                 PREDICTIONS
                                   AND MEASUREMENTS,    4(X)O RPM

                                                   -63-
       130



       125




       120




       115


                                                         H=3
 ell
eL

=      110
0
                                8101



_= los




=      loo



 |      95




        9O




        85



                                                                                             e_e=l
        8O
                                                                          â€¢    Composite of Measurements
                                                                               (Runs 8101, 8104, 8116)
                                                                          â€¢    AIIOPP Predicl:ions

              I     I       I           !         I      !      !     I         I       I       t      I
             1.0                       0.5                      0                    -0. S


                                             DISTANCEFROMPROPELLERPLANE, x3/O p

                   FIGURE       25.         COMPARISON  OF PROPELLER            NOISE    PREDICTIONS
                                            AND MEASUREMENTS,   5000          RPM
                                                         -64-
                                                 OF




     mm


                                             C


     m


                                                                           Z
     mP
     m                                                                     @
                                                                           a
                                           "-_L
                                           II
                                                             =X
     e_                                                                    m
     m                                        ,m         _   ee

                                                                           L_

                                                 L

                                                                           L_
                                                                           <


     O
     m
                                                                           L_
                                                                               Z



                                                                               L_
le   a0
m
                                                                               L_

N     P_

                                                                               Q.




         ql"
                                                                               L3
                                                                               I


         e_




         N




               I
                       $                                          $   O

                       !                                              m
                   |                                                   !
                                                     I            I


                           (sa_.z6ap)    H_, aSeqd


               X




                                  -65-
        ORIGINAL           P/'_GE i_
        OF   .p(_R         QUALITY




    _            _                   _   _   .==
I   I                I                   I   I




                         -66-
                                                    m


                                                    U
                                                    m
                                                    C_
                                                    LU
                                                    O_

                                                    I11


                                                    :E
                                                    2.

                                               .    UJ
                                               _-   Z
,M                                             I    I-
                                               ra

                                               =    ILl
                                               N




                                                    O.




                                                    LU


                                                    L;
                                                    m
                                                    i1




         I
                                      $
                                          mu
                                      I    I


             (sa_6ap)Hll      aSeqd

     M




                       -67-
way       of    proving            it      from           the       available              data.           It     is    reasonable,
at    least          until           future           measurements                   can        disprove            the       assump-

tion,          to     take       the       free           field          predictions               as      being        correct.


Blocked             Pressures


To    answer           the       question                 about          the    PAIN        model          used        to     adjust
free       field           levels          to       blocked              levels,           it    is     necessary                 to

briefly             review           the       basic           type       of    prediction                  given       by        Eq.     (43)
of    Ref.          (I).         If       _ (Fig.              3)    is       zero,        the     b_ocked             pressure               is
6    dB    greater              than       the        free          field.           The        ratio        remains              close        to
6    dB    for        _ less             than        or    equal          to    about           30 Â° , drops            only           slight-
ly    to       5.75        dB    at       50 Â° , 5.4            dB       at    60 Â° , 4.75            dB     at       70 Â° , 3.3          dB
at    80 Â°       and       finally             to     zero          at    90 o .       For       all        practical              pur-

poses,           the       predictions                    are       then       for     a 5 to           6    dB       increase            for
measurements                    within           a propeller                   radius           either          side         of    the
propeller              plane             along        the       grid          line    _=I.


How       much        do     the         pressures              actually              increase?                 Figure            29     gives
measurement                 results              from          the       free        field       and        blocked           pressure

tests           (Figures             9    and        10)       that       show        that       the        pressures              increase
(near           the    propeller                 plane)             anywhere           from        3 to         4     dB.         As     one
moves           away       from          the     plane          of       rotation           the        reflection                 effects
appear           to    dissipate                 faster             than       the     PAIN        model            predicts.                 This
implies              that       perhaps              the       PAIN       model        (which           is      based         on        some
measurements                    by       Magliozzi              (9))          should        be     modified.                  However
the       data        base       is       not        a large             one,        and     the       measurements                     are
not       for        the     same         diameter              cylinder              used       in     the         interior             noise

study.


Next,           the    measurements                       on    the        hardwood             cylinder               can    be        com-
pared           to    the       present              PAIN       predictions                  made       using           the       ANOPP
free           field       calculations                     (Figure            30).          The       predictions                  are
basically               the      data           in    Table           8 increased                 by    6       dB.       These          clear-




                                                                         -68-
       130




       125




       120




                                                                                                   H=I
       115



 al
Â¢1.

       110



Â¢n
                                                                                           1t=2
       105
L_

L,J
...J

LU
aÂ¢



L,J
       100
.=

|
        95




        9O




        85
                                                             (}     Blocked
                                                             â€¢      Free Field (Composite
                                                                    of runs 8100, 8103, 8115)

        8O




              I    !        I          I         I       I           I            I            I     I
             1.0                      0.5                            0                             _0.5

                                      Distance   fro,,   Propeller       Plane,       x3/0 p

                   FICURE       29.         MEASURED    FREE FIELD                    AND BLOCKED
                                            SOUND  L.EVELS INDUCED                     BY PROPELLER

                                                             -69-
        130
                    ORIGSNAL PAGE IS
                    0F pOOR QUALITY



        125



                                                                                        H=I
        120




        115



                                                                                  H=2
        110



a..

m,

        los
                                                                 H=3

....1                                           /                       \
u.l

                                               /                         \
._a
                                                                          \
u.l
a_
                                              /
                                             /
 _-      95                                 I                                 \         \
 X
                                            /                                 /          \
                                                                                          \
                                                                                              \



         85                                           â€¢    Measurements
                                                      â€¢    PAIN predictions
                                                           Bade ustng ANOPP
                                                           free field dat_
         8O                                                P_-dtcttons _th
                                                           PAIN blocked pressure
                                                           increase of 4d8 (max.)




              1.0                0.5                         0                          -0.5

                                       Otstance from P_opeller     Plane,x3/l) p
                      FIGURE   30.     MEASURED    AND        PREDICTED   BLOCKED                 SOUND
                                       LEVELS  INDUCED         BY PROPELLER    ON
                                       TEST CYLINDER

                                                    -?0-
ly    show       an    overprediction.


For     consistency                with       the       measurements                Of       Figure        29,       the     PAIN
predictions             can        be    modified             to    limit       the          increase           to    4 dB
(instead          of    6 dB).               For    convenience                these          predictions               are
also     shown         in    Figure           30.


3.5      Test         Comparisons

                                                                                              "\


The    propeller             noise           blocked          pressure          model              is    temporarily
assumed          to be       suitable              as    originally             programmed                 in       PAIN.         To
begin,       the       acoustic              and    structural                loss       factors           (which           are
an    intermediate                 output          from       PAIN)       can       be       compared           with       meas-
urement          data       (Table           I).        It    is    necessary                first        to    concentrate
on    the    structural                 damping          model          and    to    correct              certain           de-
ficiencies             known        to be          present          in    it.
                                                                                         \




3.5.1        Structural                 dam_ing


As    previously             noted,           the       structural             loss          factors           of    the     fuse-
lage     modes         are     calculated                for       the    particular                    trim    installa-
tion.        For       structural              mode          r,    the    loss       factor           is __r, and is
calculated             with        Eq.       (82)       of    Ref.       (I).        That           equation   has been
found       to    be    slightly               defective.


Modification                of Wr        4



In Appendix  A of this                         report,             it is       shown          that        _     of    Eq.     (82)
should  be given by

                              _=                    ____m__+_
                                                     -   2    r                 '
                                                     mrW r

                               i




        4 Nomenclature                   used       below          is    consistent                 with       that     of
Ref. (I).


                                                             -71-
where     mr replaces                m of        the        original          result,            and

                                               =ram /M x
                                           r         r      r          â€¢

                                                                       X
                                                                             is     given        by
M r is       the    total          modal        mass        and       Mr



                                          Mx             m_(X)    d_
                                           r=_x             r2



X being        the       sidewall              area       covered           _th      trim.            The     above          change
is    necessary           because              the       original           analyses           in     Refs.        (I)       and
(6)    inadvertently                 led        to       calculations               of    structural               loss        fac-

tors     premised             on    total         coverage             of    the     model          fuselage            by
trim,        and    also       failed           to       take     into       account           the      fact       that        signi-
ficant        modal       energy           of     lower          order       structural               modes        could        be
in    axial        and    circumferential                        stretching              motion         of    the       skin

(non-bending).                     The     PAIN          programming              change         required           is       given
in    Appendix           A.


Intermretation                 of    PAIN         output


Predicted           structural                 loss       factors           (output         by      PAIN)         are     to    be
taken        from     the      "Structural                  Modes"          list     only.            Loss        factors,

ETA     R',    listed          following                 "Band-Average               Loss        Factors"           and        next
to     "Trim       Factor,          dB"        are       averages           over     the       bands         indicated
and     are    wholly          fictitious                 where        no    modes        exist.             For    the
scale-model,               the      predicted               first          structural            mode        is    188.5        Hz

and     no    band       average           should           be    shown        below        200        Hz.


ComDarisons


Predicted           loss       factors            and       measurements                 are     compared           in       Fig-

ure     31.        The     calculated                 (band       average)           values            shown       are
heavily        weighted              at    the        low       end    of     the    modal            spectrum          by     the




                                                                  -72-
                                                                           .,_;,._L         PAGE           IS
                                                                         OF POOR QUALITY




               0o5     ..




               0.2
                                                                                           im


                0.1
       I,.,




              0.05

                                          \
VI

Â¢D
                                                   \
..,I                                                   \
              o.oz                                         \

Â¢Â¢
k-,
                                                                                                                                 I   I
               0.01


                                                                                   \
                                                                                       \
              O. 005                                                                        XI
                                                                                                 \
                                 â€¢      mJ.SUR[D                                                     \

                                 â€¢      CALCULATED             (BAND   AVERAGE)

              O.002              â€¢     CALCULATED          (lowest       few   s_de_11          =odes)




                            I                 I                 I              I                     I           I         I               I     I
                            20                50               100         200                       500        1000      2000           5000   10000

                                                                       FREQUENCY,Ht

                                     FICURE        31.          PREDICTED  AND MEASURED                                STRUCTURAL
                                                                LOSS FACTORS  OF FUSELAGE                                WITH TRIM
                                                                 INSTALLED,            17T = 0.13




                                                                                   -?3-
loss     factors           of     the      floor        modes         (PAIN        predictions              are       that
the     scale        model        fuselage            has       mostly        floor          modes     at    the       low

end     of    the     modal          spectrum).                 The     predicted             lowest        bona       fide
shell        (cylinder           wall)          mode       is    301.9        Hz.        Calculated              values
of    the     structural               loss      factor          for     the       lowest        few    shell          modes

are     given        by    the       solid       circles.               Basically             the    sidewall              modes
have     (predicted)                 damping          values          that      begin         _rith the          solid

circles         in    the       range          0.2-0.3          and     follow          the    solid        circles           and
the     averages           on    out       to    5000       Hz.         These       predictions              are       satis-
factory         when       compared             to'measurements                    in    the     frequency             range
of    interest.



Finally,         it is noted                   here   that           the modification    of W r'                      , as
detailed         previously,                   alleviates             the need   to arbitrarily                         limit

its     value        at    low       frequencies                as    assumed           in    Appendix           E    of    Ref.
(I).         Also     Fig.       31       of    this       report        is     the      corrected           version             of
Fig.     E-15        of    Ref.        (I).


3.5.2         Acoustic           loss          factors


The     measured           and       predicted             acoustic           loss       factors        are          shovm       in

Figure        32.         The     calculated               band       average           values       are     plotted
upon     the     scattered                individual             measurements                 from     Table          I.      Pre-
dictions         are       considered                satisfactory.                  Certainly           the          acoustic

loss     factor           prediction             model          needs     to       be    applied        to       a number
of    different            types          of    trim       installations                 before        the       quality
of    the     model        can       be    ascertained.


Figure        32 also           shows          the    predicted           acoustic             loss      factors             for
a heavily            damped          (almost           critically             damped)          trim     lining.
Damping        is     seen        to      suppress          the       tendency           to    predict           the       up-
ward     excursion              at     about         250    Hz.         This       is    the     frequency             where
the     trim     model          predicts             a resonance              of    the       lining        on       the     in-
sulation         (see       Ref.          (6)    for       some       examples           of    similar           predictions).




                                                                -74-      Â°
                                                         OR'GI_!              pAGE
                                                         OF POCR QUALITY




        0.5    B




        0.2




         0.1



                                                          â€¢                                                             Aal
,,_    0.05                                      â€¢                                             &A
._J

t,.1
(ml

I,-,

8                                                                             A!           â€¢            A                         â€¢
       o.oz _                                â€¢                            â€¢        I                                      I




        0.01                                                             Aâ€¢                         I       t       t                   â€¢




       0.005   mid




                          â€¢       REA_i_ED
                          â€¢       CALCULATED(BAND AVERAGE), nT =o. ].3
       0.002                  I   CALCOLATED (AUqOST CRITICALLY DAMPED TRIR)




                     I               I           1            I                        I                        I             I         I      I
                     20             50           100      200                  500                      1000             2000         5000   10000

                                                          Frequency,          I_
                                  FICURE     32.       PREDICTED   AND                     MEASURED                       ACOUSTIC
                                                       LOSS FACTORS




                                                                  -?5-
Since        the       trim        transmission                 loss     is        also          at    its       predicted

maximum          negative               value,        there        remains              a    question             as     to    whe-
ther       or    not       this         predicted              behavior            should             be    suppressed              by

choosing             a large            WT"      An       answer       will         be       given          after        the       inter-
ior       noise        predictions               are       examined.




3.5.3           Interior            sound        levels


Figures           33    and        34     give       the       predicted            interior                sound        levels.
They       are       plotted            on     the    measurements                     from       Figure          21     (and
Table          5).      In      both         cases        the    input         data          used          are    from        Table        6.
However           the      original             PAIN       blocked            pressure                model       (that        of     a
6    dB    increase)               was       used     for       the      predictions                   in     Figure          33    and

the       pressure           increase            was       limited            to       4    dB    in       Figure        34.        This
latter          model        is     more        consistent               with       the          results          of     Figure           29

and       thus       the      latter           predictions               are       those          that        will       be    com-
pared          with     the        measurements.                   The        differences                   between           the

predictions                and      the        measurements                  that          are    plotted           in       Figure
34     are      shown         in    Table           10.


Statistical                Evaluation


Of     interest            is      whether           there        is     a statistically                         significant
difference              on      the       average          between            the          predictions               and      measure-
ments.            Stated           another           way,       are      the       predictions                   biased?            To

determine   this,                    the       differencesA   i,                   i    = I, 2, ..., n between
the _redictions                      and       the measurements                        are computed and their
mean       A     and     standard              deviation           s     determined.                       Next      a standard

hypothesis               test        is       performed           (10).            The        hypothesis                is     that

the       true       mean       difference                _A     ( _is        its          estimator)              is    zero,        i.e.,

                                                     Ho:#A=O             â€¢




                                                                  -76-
                                                              ORIGINAL               PAGE |4
                                                              OF POOR                QUALJT'Y


       105
                                                                                         â€¢           PREOICTE])
                                                                                         â€¢           SPACE AE_r;   AT _IC           H
       IO0                                                                                   I 991[CONFIDENCE LIMI_



        95



_.     90
=l


       85




...a



                                                                                                                                \


a

|       7o

        65




                                                          /          \
                                                                         \
                                                                                 \
        55                                                                           \
                                                                                         \
                                                                                                 \
                                                                                                     \


             I     I     I      I         I     I     !          I           I               I           I    I     I       I        I
             100        200                                                                                        700              800

                                                    Frequency, He
                       FIGURE       33.       MEASURED   AND PREDICTED     LEVELS
                                              INSIDE MODEL  FUSELAGE   INDUCED
                                              BY PROPELLER




                                                          -??-
                                          ORIGINAL                       PAGE Ig
                                          OF POOR                        QUALITY




                                                                                                   A    PREDICTED
                                                                                                   â€¢    SPACEAVERAGEAT RARIÂ¢II[C H
                                                                                                    I   99Z CONFIDENCEL]M]TS
100




                          /
                         /
                         /                                  \

                                                                    \


                                                    #
                     /                                              /
                                                                                                                                           \
                                                                I
                                                        /
                                                /
                 /
                /.

            /                                                                                                         \
 60                                                                                                                        \
                                                                                                                               \
                                                                                                                                   \
 55                                                                                      \                                                 \

                                                                                               \                                       /        \
 5O



       I                      !            I                    I         I          I    I                            !           !           ,!
      100                     2OO         300                           400              500              6OO         700                      800


                                                                        Frequency, He
            FIGURE                  34.   MEASURED                         AND       PREDICTED    SOUND  LEVELS,
                                           BLOCKED                        FIELD       LIMITED  TO 4dB MAXIMUM
                                           INCREASE




                                                                              -?8-
            Table     10.   Predicted     Versus     Measured     Space
                            Average     Sound   Pressure     Levels




 RPM       Harmonic         Freq.                   _--_H (dB )
                                                                             A i
              H             (Hz)         Predicted*          Measured"
       i




3000           I            150              63.3                 81.0     -17.7
               2            300              66.2                 69 â€¢ I    -2.9
              3             450              59.5                 52.9       6.6


4O00           I            200              91.7                 90.3       1.4
               2            400              78.2                 80.3      -2.1
              3             600              71.3                 65.2       6.1


SO00           I            250             86.4                  1oo.2    -13.8
              2             500             91.1                  91.5      -0.4
              3             750             75.7                  74.0       1.7


 * From    Fig. 34,    WT=O.   13
 - From    Table 5




                                         -79-
Here       the    sampling                   distribution                 of     4    is



                                               =Stn_i/_


where       tn_ I is            the          Student           "t"       variable              with           n-1       degrees          of
freedom.              For       a       two-sided              test        at    the       a    level              of    signifi-
cance,          _ must          fall          within           the       acceptance              region                 given       by




                                -Stn_          1 ;a/2/_             _ _<_ Stn_         1 ;a/2/_i          _



In    the       present             case,        the          region        of       acceptance                    will       be    taken
quite       narrow          by          first       selecting               a    = 0.1.            Selection                   of       this
high       level       of       significance                       increases           the       possibility                       of    a

so-called             Type          I    error        where          the        hypothesis                    may       be    rejected
when       in    fact       it          is    true.



The     hypothesis                  test       is     performed                 a number           of             different             ways.
First,          all    of       the'data              are          pooled        providing                    a    sample          size
n    = 9    (3 rpm          x       3    harmonics).                     The     sample          mean              and       standard
deviation             are       computed              to       be


                                    _=        -2.32           dB    ; s=        8.32       dB         .



For     the      two-sided                   test     at       the       a = 0.1           level              of       significance



                                        t8;0.05           =    1.86             ,


and     the      acceptance                   region           for       the     hypothesis                       is



                                    -5.15                                                  .

Since       the       sample             mean       _ (=           -2.32        dB)     falls             within             the    accept-
ance       region,          the          hypothesis                 is     accepted.                  It          is    also       accepted



                                                                                                       _JRIGINAL PAGE i_I
                                                                     -80-                              OF POOR QUALITY
if    the     level          of       significance              is    increased                 to        a = 0.2

(Table        1I).


Next     the       hypothesis                is     tested       by     considering                      the       data       for
each     propeller                speed        and      harmonic         separately.                          In    these

cases,        the sample size is                          n = 3 and           t2;0.05                =    2.92.    The
values        of A and s and the                          acceptance           regions                   are given    in
Table        11.        Results             for     a = 0.2          level        of       significance                      are
shown        for       these          tests       also.


For     the       test       where          all     nine       datum     are          considered,                   there          is
not     a statistically                      significant              difference                    on    the       average
between           predictions                and       measurements.                   However,                there          is    a

substantial              random             error       indicated            by       a standard                   deviation
of    8.32        dB.        A    discrepancy              of    more        than          8    dB       can       be    expected
for     about          one       out    of     three       predictions.


When     the       test          is    performed           by    rpm,        the       hypothesis                   is       accepted
in     all    cases.              However,             there     is     also          significant                   random
error.


Testing           by    harmonics              leads       to    acceptance                    of    the       hypothesis
for     H =       I,    and       rejection             for     H = 2        and       H       = 3       at    the       highest
level        of    significance                   (each        test     by    harmonic                   leads          to    accept-
ance     at       a lower             level       of    significance                  say       a =       0.05).              Rejec-
tion     of       the    hypothesis                 for    H    = 2     and       H    = 3,          is       an    admission
of     bias       being          present.              However         the     sample               mean       error          and
standard           deviation                are     small.


If     data       for    H       = 2     and      H = 3        are     pooled          (n       = 6),          the       hypothesis
is     accepted           even         at     the      a = 0.2         level          of       significance.


Discussion              of       Results


Although           the       hypothesis                tests     have        led       to       the       conclusion                that


                                                                -81-
            Table      1 I.     Sample Statistics     and Acceptance        Regions
                                for Interior     Sound Levels  (Table       10)



 Hypothesis                       Sample             Level      Ac c ept anc e
    Test                       Statistics               of         Region        Accept?
            on                                   Significance      (+dB)
                               _(dB)    s(dB)         a             -

All     9    datum
                                                      o.i           5.15              yes
(3    rpm        x 3           -2.32     8.32
                                                      0.2           3.87              yes
harmonics)

3000        rpm                -4.67    12.24         0.1          20.63              yes
(3 harmonics)                                         0.2          13.32              yes

4000        rpm                +1.8      4.38         0.1           7.36              yes
(3    harmonics)                                      0.2           4.76              yes

5000        rpm                -4.10     8.47         0. I         14.27              yes
(3    harmonics)                                      0.2           9.22              yes

H= I
                                                      0.1          16.99              yes
(3    propeller               -10.0     10.09
                                                      0.2          10.98              yes
speeds)

H=2
                                                      0.1           2.15              yes
(3     propeller               - I.8     I. 28
                                                      0.2           I .39             no
speeds)

H=3
                                                      O. I          4.33
(3     propeller               -4.86     2.58
                                                      O.2           2.8O
speeds)

H=2     + 3
                                                      O. I          3.40              yes
(3     propeller               +i .53    4.o8
                                                      0.2           2.46              yes
speeds)

8    datum
                                                      0.1           4.28              yes
(H= I , 3000           rpm     -0.4      6.41
excluded)                                             0.2           3.20              yes




                                                  -82-
there       is          some          bias       in    the          predictions,                 the       error          that       has
been       identified                      is    not       large             and    is    considered                 an    accept-

able       error             at       this       time          (after          flight          comparisons,                 its
acceptability                         will       be    re-examined).                          The     large          random
error       is          due       to       inaccurate                   predictions             of       the     interior
levels          at          the       blade          passage             frequencies.                    Now     a    discrepancy
of    4 or          5       dB    might          (barely)                be    tolerated              for       one       out     of
three       predictions,                         but       8       or    9    dB    cannot          be     tolerated.                To

determine                   whether             further             modifications                   are     necessary                (be-
yond       those             of       Appendix             A),          it    is    necessary              to    closely             exam-
ine       PAIN          predictions.


Appendix                B    contains                the       basics          of     the      PAIN        output          for       the
three       propeller                      speeds.              The          first       48    structural                 modes        are
listed           (out            of    300       total          used);             also       the     first          48    acoustic
modes       (out             of       400       total).                 The    distribution                 of       modes        in       one-

third       octaves                   is    then       given.                 Next       the     calculated                trim
properties                   are       presented.                       The    Trim       Factor,           dB,       is       a trans-
mission             loss          (negative                implies             an    increased              transmission).
Following                   these          data       the          propeller             noise        input          is    tabulated

for       the       first             three          harmonics.                    Data       input        for       the       grid        of
Figure          3       are       used          to    create             the       data       for     the       large          (16     x    19)

grid       as       discussed                   in    Section                3.4.2.           Note       L=#+9,           so     the       data
for       J=1       to       10       of     Figure            3    are       found       in     L=IO       through              19.
The       tone          transmission                    predictions                   come       next          followed
by    a    tabulation                      of    the       five          highest          contributing                    pairs        of
acoustic                and       structural                   modes          that       make       up     the       predictions.
The       propeller                   noise          data          and       the    interior             predictions                 for        the
3000,       4000,                and       5000       rpm          cases       are       given        in    sequence.


The       lowest             computed                structural                mode       occurs           at    188.5          Hz.         From
the       values             of       the       generalized                   mass,       it     can       be    seen          that        this
is    a    floor             mode          since       most             of    the     contributing                   energy          is     in

the       floor             (the       output          of          MRP       can    be    used        to    see       the       mode        shape




                                                                              -83-
if    desired).                Note     that          the    first          true        cylinder              (shell)           mode     oc-

curs     at       301.9        Hz,     followed             by    another              at    318.7           Hz    and     another           at
346.7        Hz    and     470.5        Hz,       etc.           Since       the        first           harmonics             (blade

passage           frequencies)               occur          at    150       Hz,        200    Hz,        and       250     Hz,     al___l
shell        (sidewall)          _ modes          are       being        driven             below        their          resonance
freauencies               (wrimarily              because           the      model           cylinder              is     too     short)

and     reswond           in    "stiffnesslike"                     fashion             for    H=I.               However,         the
frequencies               of    the     second          and       third       harmonics                  are       at     300    Hz     or
above        and    in     these        cases,          resonance             and           mass        controlled              struc-
tural        modes        are     usually             dominant           contributors.


Consider           the     cases        for       H=I.           Floor       modes           dominate              transmission

at    3000        and     4000       rpm.         The       shell        mode          at    301.9           Hz    is     contribu-
ting     substantially                  at       5000       rpm,       as    is        another           shell          mode      (num-
ber     8)    at 318.7            Hz.        Both       are       stiffness                 controlled.


The    H=2        cases        are     as    follows:             At     3000          rpm,     the          shell        mode     at

301.9        Hz    is     resonant           and       dominates             the        transmission.                      A mass
controlled              shell        mode        at    346.7        Hz      dominates               at       4000       rpm.       A
mass     controlled               mode       at       470.5       Hz     dominates                 at    5000       rpm.          The
latter        mode        has     significant                 sidewall             and       floor           motion.


The     H=3       cases        (all     rpms)          are       a "mixed-bag"                  in       that        the      predic-
tions        are     dominated              by    structural                modes           having           significant               side-
wall     and        floor       motion.


Now     consider           the        predicted             trim       TL.         Note       that           at     150    HZ     it    is
about        -7     dB,    at     200       Hz,       -17.3       dB,       and        at    250        Hz,       -4.8     dB.         The
large        negative           value        might          at     first        appear             to    cause          the     predic-
tion     for       H=I      (at       4000       rpm)       to    be     better             than        it    would        have        been
had     this       behavior            not       been       predicted.                  However              the     trim       model
compensates               for     this       and       when       the       resonance               effect           is    forced         to

disappear            by    increasing                 UT,     the      prediction                  for       the     4000        rpm,     H=I
case     changes           only        slightly             (as     will          be    seen        shortly).




                                                              -84-
Note     the     acoustic                  mode dominating                the    transmission.                For        H=I at
4000 rpm,            it        is     mode 3 (q=2,i=O)                  at    187.6     Hz.     This         mode domi-
nates only for small UT"                                  Also note that acoustic    modes 6, 7,
and 8 have â€¢ very high loss                               factors  (0.6-0.7).   These high loss
factors  will   be predicted                              only when and where the trim    reso-
nance is predicted.    Now if _T is increased      significantly,                                                             say
too 2, the trim resonance  effect  will  disappear     (the trim                                                         TL
changes         to        +1.2         dB at       160 Hz,         +4.6      dB at     200 Hz,        and +8.7            dB at
250 Hz).             Simultaneously,                       the     high      values     of    the     acoustic            loss
 factors of modes 6, 7, and 8 will fall.  Un is                                                 reduced to 0.088
 for mode number 6, 0.077 for mode 7, and 0.081                                                 for mode 8.   More-
over,  with the larger   UT'                               the prediction for H=I at 4000 rpm is
dominated   by the response                                of modes 7 and 8 (not 3 anymore).  Yet
even with these dramatic differences, the predicted                                                         interior
level is about the same (91.2 dB as opposed to the                                                         original            91.7
dB) .


The predicted                   results   for the case of NT=2 are given in Figure
35 and Table                   12.    As can be seen the errors  (compared to those
in     Table     10)           remain            about     the     same.        However       the     H=I,     5000 rpm
prediction                is        significantly             better.           As before,           the     H=I,        3000
rpm     prediction                   has the        largest         discrepancy.              This     particular                da-
tum is         unique           in        that     the     blade     passage          frequency        lies         in    a re-
gion where non-resonant     behavior   of the cavity  is necessary   (150
Hz lies   between the first   and second acoustic    modes).   It is not
felt   to provide a good test    for the PAIN model,    and for this
reason,         the H=I, 3000 rpm datum is tossed                                       out.     The other  eight
remain         (a case could probably  be made for                                      throwing    out the data
 for    all   of the                 H=I     cases because of the                     known difficulty                   of    mak-
ing     predictions                   in     the stiffness-controlled                     region).


Now when the hypothesis test is performed                                                on the data in Table 10
(with the H=I, 3000 rpm datum excluded),                                               the mean error  and stand-
ard     deviation                   are     found        to be
                                          _=-0.4          dB ;      s = 6.4       dB      ,

                                                             -85_
             Table       12.     Predicted      Versus   Measured    Space
                                 Average      Sound   Pressure    Levels




 RPM        H armoni     c                  SP--T
                                                H (dB)
                                                                            _.
                  H              Predicted"           Measured               l


3OOO              I                  62.1                 8_.0         -18.9
                  2                  65.5                 69. I            -3.6

                  3                  56.9                 52.9              4.0


4000              I                  91.2                 90.3              0.9
                  2                  73.8                 80.3             -6.5

                  3                  67.4                 65.2              2.2


SO00              I                  92.9                100.2             -7.3
                  2                  89.6                 91.5             -I .9
                  3                  74.0                 74.0              0.0



 W T =2.0    to       suppress    predicted       trim   resonance




                                               -86-
                                                                         ORIGINAL                   PAGE                     IS

                                                                         OF       POOR              QUALITY



                                                                                                                                             â€¢       PREDICTED

      105                                                                                                                                        O   SPACE AVERAGE AT HARRONIC H
                                                                                                                                                 I   99$ COIIFIDENCE LIH['I'S


      100



       95



eL     90


                                                                                                            /
                                            \
       85                                                                                   "           /
                              I                 \
em
                  \           I                     \                                               I
..3                                                                                             I
       8O                     /                              \                              /
L,J
                                                                 \
                                       4,                            \
       75
L,J
ee
                          I                                                   \         .
eL
                         I
 me
       70               T/
                        =1
                         I
       65                I                                                                                                                   /             \
                                                                                                                                                               \
                                                    /                                                                    4,
                                                                                                                                                                       \
                        I                                                                                                                                                  \
                                                                                                                 /                                                             \
                        1
                                                                                                                                                                                       \
                                                                                                                                                                                           \
        55   --
                                                                                                                                                                                               \
                                                                                                                                                                                                   \            J
                                                                                                                     \
        50   _                                                                                                               \
                                                                                                                                 \                                                                          \
                                                                                                                                     \
                   I,    I         I                     !           I              I               I                    I               I            !            I               I                    !
                                                        300                       400                                see                             600                       700                     8O0
                  100             20O

                                                                                  Frequency,                    I_

                        FIGURE              35.         MEASURED  AND PREDICTED    SOUND LEVELS,
                                                        BLOCKED FIELD = 4dB (MAX), CRITICALLY
                                                        DAMPED TRIM PANEL




                                                                                        -8?-
and     the     acceptance                region        is   +3.2         dB     at       the_=0.2            level           of

significance.                    The      hypothesis           is        still        accepted,             and        the
random         error        is     almost         tolerable.               Performing                the      hypothesis

test     on     the     data        of     Table        12    with        the        H=I,     3000       rpm       datum

excluded,            the     mean         error     and       standard               deviation           are       found           to

be


                                    A=-1.5           dB      ; s     =    4.05         dB          ,



and     the     acceptance                region        (fora=0.2)                   is     +2.0     dB.         In      this

case     also        the     hypothesis             is       accepted.                Moreover           here,           the

random         error        is     felt      to    be     (barely)              tolerable              (s=4       dB).



It     can     now     be        safely      stated          that        the     PAIN        model         seems         to     work.   _

It     has     done     a    reasonably             good       job        of     predicting                the     scale-

model         test     results,             and    its       testing            in     application                to     real

aircraft            isneeded              next.




                i




                                                              -88-                             C
4.0      PROGRAM        UTILIZATION:                     FULL     SCALE          AIRCRAFT


Capabilities            and       limitations              of        the       PAIN        software          for        flight
predictions            in    the       case        of    real        aircraft              are    considered                 in
this     section.            Basically              the    focus           here        is    on       learning             about
some     of    the     types          of    problems           that        a user           will       be    confronted

with     when     a particular                   aircraft            is    selected              for       study.            As
will     be    shown,        PAIN          has     some    limitations.                      But       in    many          re-
spects        these     are       not       major        problems              for     the       user.           The       soft-
ware     is    capable           of    making           predictions               for       practically                 any       air-
craft        configuration.                   There       are        limits           as    to    the       number           of
propeller         harmonics                that     should           be    attempted,                 and     there          are
circumstances               where          the     propeller              noise        field          on    the       fuselage
may     decay     too       slowly          (spatially,               away        from       the       propeller              plane)
for     the    user     to be          assured           that        a valid           prediction                is     being       â€¢
made.


4.1      Modeling           of    the       Aircraft


A useful         approach             to    the     modeling              of    an     aircraft             is     to      begin
with     a    sketch        such       as     shown       in     Figures              36,    37,       or     38.          Here
three        aircraft        are       used        to    illustrate               the       type       of     geometric
information            that       must        be    generated.                  For        instance,             the       length

of     the    fuselage           cylinder           must        be    defined.               This          can     be      taken
as     the    actual        length          of     the    cylindrical                  section.               It      should           be
kept     in     mind    that          there        is    room        for       judgement              here.           It     may       be
confirmed         in    the       future           that     the       cylinder              should          be     longer          than
the     cylindrical              section           of    the     fuselage              (i.e.,          that        better          pre-
dictions         will       be    made        if    it    is     assumed              to    be).           But     presently

this     length        is    chosen           on    the     premise             that        details           pertaining                 to
the     termination              of     the       cylinder           are       going        to     wash       out       in    the

frequency         range          where        the       tone     transmission                    is    of     concern.
That     is,     some       errors          in     the    modal           characteristics                     in       the    low
frequency          range         will       be     accepted,              assumed           inconsequential                       as     to




                                                                -89-
                                                                                ORIGINAL       PAGE   I_
                                                                                OF POOR    QUALITY




                                                                        Spatial decay
                                                                                                                     p.
                                                                        for propeller
  ..2
  LU                                                                    tip clearance
               "iS   --
                                                                        = 0.06 0
  ,,,a
                                                                                 P

  i
  =_          -I0

  0

  0
              -15    -
      L                                                                                               0.56       =                         l           /
                                                                                                                     __ 2                          /
                                                                                                                                               (i = 76.3 Â°




              -25    -

                                                                                                       Grid      Length = 15_ = 0.82Dp                       = 0.24L

      x31 _                 I          II      !    I     I             I
                          1.0    0.i           0 -0.5-1.0-1.5
                                        I          I

                                       Io      k.P   I              5                      10         /-     7       15
 L                                                                                                                    /            =--;m
1.68                      _             _6               = k (axi_il index)It--/                           /_=
 '1

  F"                      'r           X,i 1             i
                                                ,..._--1--_      .,..       /    z.z8                 ",___
              - Dp = 2.69

                                                                        /
                                                                        I                             Grid Spacing

                                                                        /                              4 =       _a/18         = 0.147m
                                                                    I
                                                                 /                                         Requir_nt
                                                                 /
                                                                                                      a.(k-1)             <_
                                                           i---/                                               P             P
                                                                                                             0.147        (k_-l)           <1.12

                                                e--.-.1.12                                                   kp<8.61        p
                                Ep_
                                                                                                 Choice:         kp = 8 (this  is opti_    -
                                                                                                                 since it centers  grid on
                                                                                                                 propeller            plane)


                                                              L = 9.27



                                                                SC._UE:           1in   = 5m

                                 FIGURE              36.         BUSINESS/COMMUTER                           AIRCRAFT




                                                                                   -90-
             I              !           I                 1
             0         -O.S           -1.0           -1.5
                        I
                        I

                                                                                                   E
2.29

                                                                                   \       \
                                                                                       \       \




                        i                             /
                        I                         /
                        t                        /
       2.5       :--    t                        /
                            I                /
                            i                /
                            I
                            i               /
                            I      /
                            L__../


                                        I    :       1"11




                                  Scale:                  1 in =

       FIGURE                   37.         SMALL                BODY   AIRCRAFT


                                                          -91-
ORIGINAL PAGE 19
OF POOR QUALITY                                     I                                                                                        PAIN
                                                            0.40p
                                                    I                                                                                  ___6rid
                                                    I
                                                                              Spatial                     decay-_

                                                                              for         propfan
                                                                              tip         clearance                                    _r      = 6.79
                                                                                                                                              P
                                                                 I            = 0.80p




                                                                 I
                                                                 I
                                                                 I
                                                                 I
                                                                 I
                                                                 I                                                               Grid Spacing
                                                                 I                                                               4-_a/18    = O. 328m
                                                                 I                                                               Grid Length = 15,4 = I. 300p. = O. 21L
                                                                 I
                                                                 I
 x3/D p                                                                                                                                                              /
                                                                                                                                                                 /

                                                                                                      15
          0

                    PAIN Grid
                                                                                                                                                                 \
                   Grid Index      k = 1---_    8.--12.--16                                               I                                                          \
                    (k = 4)                Xl \                                                           I
                                                                                                                          6.79
                      P                        _    \\                                                    I

                             ?., I _',
                          = 3.78                r" --      h
                                                                                                          I
                                                                                                          I


                                                                                              \               \
                             _       /                    ---\                                    \               \
                                                                      \                               \               \
                                                                          \                                   \\
                                                                              \
                                                                                  \                               \\\\
              _â€¢          tp = 7.5       --_                                          \                              \\
                                                                                          \                            \\

                                                                                                      \
                                                                                                              \\            \ \




                                                         L = 23

                                               SCALE : 1 "in = 5m

                      FIGURE         38.        NARROW               BODY AIRCRAFT                                                 -
                                                PROPFAN               CONFIGURATION


                                                                     -92.-
their       effects           at    the       blade          passage          frequency           and       its       harmonics.
After       the      length         L        is    determined,                the     remainder             of       the     infor-
mation       will        be    fixed          by    the       aircraft             configuration.                     The       loca-

tion of          the â€¢propeller,                    given by the radius                        rp, angular   position
   , and         axially   by z                   is to â€¢be specified.                         These parameters     are
exactly          the     same       as       _efined          in    Figure          2.


The     three        aircraft            shown          have       been       chosen        to    illustrate                 the

ranges         of    parameters                which         will       likely        confront             the       user.
In    most       circumstances                    the    propeller              will      be     larger          in    diameter
than     the        fuselage.                This       will       almost          always        be    true          whenever
there       are      only      two       engines             (propellers),                and     will          lead       to    a
limitation             on     the       allowed          range          of    the     propeller             tip       clearance.

The     PAIN        software            is    designed             to    take       the     propeller                noise       sig-
natures          over       a grid           that       covers          a length          of     the       fuselage             equal
to    15_      , where          _       is    given          by     _a/18,          and         a is       the       fuselage
cylinder          radius.               For       the    busimess             aircraft           shown          in    Figure          36,

the     grid      length           is    0.24L          or    0.82Dp.              For    the     small          body        air-
craft       of    Figure           37,       it    is    0.23L          (0.82Dp)          and     for       the       narrow

body aircraft   of Figure                           38, the grid   length                       is 0.21L  (1.30Dp).
The optimum   is to have                           a long  grid length,                        i.e.,  as a percent-

age of both                 L and Dp.   Over   the length   of the grid,    it is
desirable   to              have a significant    decay   in the sound   pressure
levels         (at     each        harmonic)             to       assure        that      most        of    the       acoustic

energy       is      being         taken          into       account.              The    grid        length          is     fixed
by    the    radius           of    the       fuselage,             thus        when      the     propeller                diameter

is    significantly                 larger          than          the    diameter           of    the       fuselage,
there       is      conceru         that          the    propeller              noise       field          may       not     decay
rapidly          enough        over          the    length          of       the    grid.         This          concern          is

aggravated             by     the       fact       that       the       cylinder          length           to    diameter
ratio       ( L/D        ) of       a typical                fuselage           (cylinder)             is       in    the       range
between          about        5.3       and       6.3,       and    thus        the      grid     is       never       going          to
cover       more       than        about          20-25%           of    the       length        of    the       fuselage
cylinder.              To     top       this       off,       the       decay       of    the     propeller                field        on




                                                                   -93-
the     fuselage                is     highly             dependent                 on       the        propeller               tip      clearance.



Consider               the      airplane              in     Figure              36.          The        diameter               of      the      pro-

peller            is    more         than        a meter               larger            than           the        diameter             of      the

fuselage.                 The        tip        clearance                 is     0.165m             or       0.06        Dp.         The        se-
lected            grid       location,                with           the       axial          index            k=8       lying          in      the

propeller               plane          (i.e.,             k=kp),            puts         the        forward-most                     position

on     the        grid       at      x3=7_           or     1.02m           (0.38            Dp).            The        aft-most             posi-

tion    is         x3=-8_          or -1.18m   (-0.44    Dp).                                   Figure              39 shows   that                    the
overall            sound          level  at the   forward-most                                     grid             point  (k=I,_=I)                    _

can     be        expected             to       be    about            10      or      11     dB        below           that       at    the         pro-

peller            plane.             At     the       aft-most                 grid          point           (k=16,_=I),                 it       can

be     expected              to      be     13       or     14       dB     below            the        level           at     the      propeller

plane.             But       if      the        tip       clearance                 is       increased                  to     0.2      Dp      these
values            would         drop        to       only        4     dB      and       6    dB        respectively                    (see

Figure            37).          Thus        if       the     tip           clearance                exceeds              about          (0.2          to

0.3).Dp,               the      PAIN        model           probably                should              not        be    used.           However
this      is       not       an      unhendable                  rule.              The       spatial                decay         of      the

overall            level          as      plotted            versus               tip        clearance                  in     Figure           39     is

usually            dominated                by       one     harmonic                  (the         blade            passage            frequency).

The     2rod       and       higher             harmonics                 will         decay            more         rapidly.                 Figure

39     can        be     used        as     a    guide            to       gain        some         insight              into         the       likely

nature            of     the      computed                propeller                 noise           field.               However,               ulti-

mately,            the       predictions                    made           with        the       propeller                   noise         program

must      be       used         to     determine                 if        sufficient                   spatial              decay         is     pres-

ent.



The     axial            location               of    the         grid         is      to     be        selected               such        that         the

peak         overall            sound           level        occurs               as      near          to     the       center            of     the

grid         as    is     possible.                   In     the           turbo-prop                   circumstance,                        since         the

tip      clearance                is      limited            to        about           0.2         Dp    to        0.3       Dp,      the        grid

should            be located               with  the                 axial  index   kp                        set   to 8 or                  9.   The
entire            grid  must              be located                  on the   fuselage                          cylinder,                   thus

there         is       a requirement                       that        _.(kp-1)<Zp.




                                                                            -94-
I    L   !       !       I       I        I       I   !           !       !   I   I

    'T   I   I       I       I        I       I       I           I
                                                                      I       I


                     9P "0 = _:x _e LaAa3 aJ              ldSVO




                                     -95-
For instance, in Figure  36, kp must be 8 or less.                                                           Since kp            =
8 (or 9) is optimum,  the choice is 8 in this case.                                                           For the

aircraft             of Figure   37, kp could   be selected  as high    as                                          13 and
the grid             would  still   remain  entirely   on the cylinder.                                              However

again       the       optimum          value       is    8 or        9,    so    8 is       the       selected           value.


In    a Propfan             configuration,                 the       tip    clearance             will       be     in-
creased           significantly                  because        the       exterior          levels        will       be     so

intense.   The tip clearance                              shown  in Figure 38 is 0.8 Dp.   At
the flight Mach   number M =                             0.8, the peak overall  sound pressure
level       will       occur          aft    of    the     propeller             plane.           Reference              12 has
been       used       to    predict          that       the     axial       location             of    the    peak        level

will be           x3 = -0.4 Dp.     Predictions                            are that the exterior    levels
for the           Propfan  configuration     will                          decay  more rapidly  than   for
a    turbo-prop.                 In    the       present        circumstance,                   the    decay        is    ex-
pected          to    exceed          10    dB    at    the     extremes             of    the    grid       even        though
the     tip       clearance            is    quite       large.            In     this      particular              case,        in
order       to       center          the    grid       about        the    peak       overall          level        (i.e.,
have       the       peak       lie    somewhere           between          k    =    8 and       k    = 9),        a value

of    kp    =     4 is      selected.


The    noise          signatures             (Fourier           amplitudes                and    phases        for       each
harmonic)             are       to    be    computed           at    the    160       grid       points        as    given
in    Section          3 of          Reference          (2).         That       calculation             completes            the
description                of    the       exterior        pressure             field       required          by     the     PAIN
program.


4.2        Modeling             for    Cabin       and     Fuselage             Modes


The     next         step       is    to    determine           the       modal       properties             of     the     fuse-
lage       (both       the       structural             and     the       acoustic          properties).


4.2. I          Cabin


The     2-dimensional                  (cabin          cross-sectional)                    modal       properties            are


                                                                -96-
computed         with          the       program                CYL2D.            That          program           requires             the

floor     angle    80           as an input.                          Figure   40               shows  typical                cabin
cross     sections              such as might                         correspond                 to the three                 aircraft

being     studied              here.                 In    the    cases              of       the    small        body       and
narrow        body       aircraft,                    the       floors           extend             from      sidewall            to    side-
wall.         The     intersection                         of    the        floor             surface         (or      its     extension)

with     the     sidewall                 skin            defines           the       floor          angle.            CYL2D        computes
the     mode     shapes             in            2-dimensions               for          a    cylinder           with       floor          parti-
tion     having         unit         radius.                    Thus        the       cabin           diameter          is     of      no    con-
cern     until         the      PAIN                program       utilizes                    the     CYL2D       output          file.


Business         aircraft                 such            as    that        of       Figures           36     and      40    typically
have     a rather              small                diameter          and        a    recessed              aisle.           In     the

present         case       a floor                   angle       of     50 o is               selected           because          70%       of

the     floor        surface              is         at    the    level              defined           by     80=50 o .           More-
over,     when         the      structural                      modes        are          computed,              the     cabin         sidewall
surface         should          match                the       cabin        space.              In     the       present          case,           the

cabin     floor          lays        over             frames           with          webs       extending              downward             to     the
shell.          Thus       it       is            desirable            to    model             the     shell-floor                juncture
as    rigid      at      the        floor             line,       i.e.,              to       place      the      floor        at      50 Â° .

Since  the angles                    0o             appearing   in the acoustics                                  program          CYL2D
and the structural                                program    MRP must match,   500                                is the          best   over-

all     compromise.


The     headliners              and               baggage        storage              (shown           in     phantom          in      Figure
40)     are     ignored.                  Presently                CYL2D             cannot           handle        these         details.




4.2.2          Fuselage


The     next        step       is    to             prepare        the       input             data        for    the       program              MRP.

Table      13       contains                  the      ty_e      of     structural                    information              that         is
                                              /

                                         i"




                                                                        --97-
                           ORIGINAL   PAGE    IS
                           OF POOR    QUALITY


                                                     0.055(2.1        in)   = tri! thickness

Business   Ai rcraft


                                                       *'TT
                                                    1.47       0.84
                                                                        1.38   1.52


                                                                                l
                                                                   o.14 (5.5 in)




                                                       0.075     (3 in)

Stall   Bocl_' Aircraft:



                                                    1.61
                                                                                T
                                                                               1.68




                                                    0.1(4      inches)

   Narrow Body Aircraft



                                                                                2.4




                 FIGURE        40.    CABIN        FLOOR         ANGLES


                                                -98-
-99-
i
needed.          Typical           values           of    section           properties                 are       given        which

allow       comparisons                between           the     smaller             and     larger          aircraft.
Structural            details           of     fuselage             and     floor          stiffening                 elements
are     required         before           the       type       of    data        in    Table           13    can       be     gen-
erated.          Stiffener               properties,                skin        thicknesses,                 shell          and
floor       surface          densities,              and       seating           arrangements                    are       needed.


Note     in     the     table          that     there          will       almost           always           be    a variation

in the        fuselage             skin thickness.                     Some          value       t s must             be    chosen,
and an        average            is recommended.


Usually         the     shell          frame        and    stringer              properties                 and       their

spacings         If     and       I s will          be    uniform.               The       stiffener              cross-sec-
tional        areas      AS       and     A s are         used       with        the       spacings              to    determine
the     equivalent               shell        thickness,             i.e.,


                                   te =        ts+AR/lf+A/1                 s


The     shell     surface              density           (including              skin        and       stringers)                is     then

m=Pte,        where          p    is     the    mass       density              of    the       material              (it    is
assumed         that     skin          and     stiffeners              are       of    the       same        material).




The    moments          of       inertia        of       the     frames          and       stringers              are       to     be
computed         about           the    inner        surface           of       the    skin.            The       values           given
in    Table      13     are       for     the       typical          stiffeners                 shown        in       Figure          41.
The     shell     bending              rigidities              are     defined             by


                                        D o=EIf/1f ; Oxs=EIs/ls                                    "
The     floor     properties                  are    similarly              computed,              however,                there        is
usually         going        to    be     a    greater          degree           of    flexibility                    in    the
modeling         of     the       floor        because          many        of       the     floors          are       not       free

standing         (do     not       run        unsupported              from          sidewall           to       sidewall).
In    the     business            and     small          body       aircraft,              the     floor          is       normally




                                                               -I01-
                                                                             ORIGINAL PAGE I_
                                                                             OF POOR QUALIFY


      Business     Aircraft



                                                                                                                                      Floor
                          1.52R

      -'_-- ('_           _..     1.6                  ?                                        klorking     depth       II
      22"2 _1                        27                51
                                                                                                            zos _I_-     1-o2
                                                        w    -'P    4"---      1.02                                _--F_
           Stringer                                T                ."i_-I
                                                                   Frame
                                                                                                                     Floor      Frame




_11      Body Aircraft

                                                                                                                                         Floor




                                                                                                                                      Frame




                                                                                                                               =\,
                                                                                                                                                 Ski n =_
                                                                                                                              Floor   Frame
                                                            Fragm




                                                                                      _'_    25.4_     "I
         Narrow     Body Aircraft




                                                                               1.63
                                                                                                 Shear        61
                                                                                                  Tie
            31.8      _                     0.81



                                                                             St_ ncjer       I! Clip


                          Stringer                                               Frame                 Fail-_fe       Strap



                                                   Oimensions           in   =illiwte_

                      FIGURE              41.      TYPICAL              AIRCRAFT            CONSTRUCTION




                                                                             -I02-
built        over        webs     formed           by    increasing             the     depth        of    the     shell
frames.            In     the     case        of      the     business          (smallest)             aircraft,             the
assumed           properties            of       the     transverse             floor        beams        are    based        on
the     material              depth     beneath             the     aisle       floor,          that      is,    that        which
remains           after        material            already          assigned          to     the     shell       frame        is
excluded.                In    the     present           case,         the     floor       frame       depth       is    taken
to    be     0. I05m          (refer        to     Figure         40).


The     transverse               floor        beams         on    the     small       body       aircraft          (which
can     be    properly            described              as      extensions           of     shell        frames)        should
be    assumed            to    have     a working                depth       (below        the     floor)        no     greater

than       the     height         of    the        frame         web    above        the     shell        skin     required
to    yield        the        frame      stiffness.                 Simply        define         the      floor       frame
(transverse               beam)        such        that       its      stiffness           equals         the    shell
frame        stiffness.                Once        the      floor       stiffness            gets      that      large,           it
should        not        matter        that        there         may    yet     remain          some      uncertainty              as
to    its     actual           working           stiffness.


Generally            properties               of      longitudinal              floor        beams        should        be    de-

terminable               from     drawings.                 For     the      small      and      narrow         body     air-
craft        here,        they        are     simply          taken       to    be    roughly          equivalent             to
the     shell        stringers.                  Intercostals                should        be    accounted            for     as
increased            mass        and     stiffness               (i.e.,        thickness)of                the     floor

plate        if    necessary.


In    actual         case        of    narrow           body      aircraft,           where        the     floor        extends
sidewall            to    sidewall,              floor        stiffeners             (beams)         should        be    iden-

tifiable            from        drawings.               Table       13 contains              some      estimates             of
their        section           properties.


The     business              aircraft           is     complicated             by     the      presence         of     the
aisle.            The     longitudinal                  floor       beams       here       are     assumed         to    be       the
walls        of     the       aisle      (0.14m          high)         with     thickness            of    1.02mm        and
an    average            spacing         of      0.43m.           This       leads      to      a very       stiff       floor




                                                                 -IO3-
( fore-to-aft).


The    bending          rigidities                of    the       floor           stiffeners                  are    given        by


                                     Dyp=EI/ly               ; Oxp=EI_l                   x          ,
and     the      equivalent             floor          thickness                is


                                     tPe = tp+A_lx+A/ly


Program          MRP     will        accept        both          the       equivalent                floor          thickness            and
the     floor         surface          mass       per       unit        of      area.           The       latter        is

                                                   m    = ptPe
i.e.,       if     there        is     no    dead       weight             on     the         floor.           The     dead       weight
of    seats        must      be      added        when       seating              is      present             since     the        seats
are     rigidly          attached            to    the       floor           or      to       the    supporting               floor
structure.               The      passenger             load          is     assumed            to       be    dynamically
isolated.


On    the     business            aircraft             of    Table           13,       11      seats          have     been        assumed

at    8.62 _kg/seat               (19       lb/seat).                 The       distributed                   surface         mass       be-
comes       13.66        kg/m 2        (as    opposed              to      4.18        kg/m 2 without                  seats).                In

the     case       of     the     small       body          aircraft,                13       seat       rows        with     3    seats
per     row      (19     lb/seat)            yields          a     floor          mass         of     19.68          kg/m 2       (as
opposed          to     5.29      kg/m 2 without                   seats).                For       the       narrow        body        air-

craft,        23      seat      rows        with       6    seats/row                increases                the     floor        mass
to    23.64        kg/m 2       (as     opposed             to     7.83         kg/m 2 without                      seats).         The

seating          mass      per       unit     of       area        is      based          on    cabin           floor       area

(length   L c) since   this leads                                to     the highest  value   of rap.                                 The
important    thing   to note here                                is     that the total   dead weight                                  of
the     loaded          floor        when      seats          are       present               may    be       2 or     3    times         the
combined           weight         of    the        floor         and       its       supporting                 structure.                A
reasonable              estimate            for     seating             loads          should            be     included.




                                                                  -IO4-
4.3      Modal     Characteristics                   of    TyDical          Airplanes


The     aircraft        selected          for       the    present           study        represent                   signifi-

cantly        different         scales         in    terms       of     size       and        stiffness                of
fuselages.             The    largest          aircraft          conforms            to       a narrow                body,        and
it    was     selected        because          it    is    considered              to     be       the       largest           tur-

boprop        airplane        likely        to      be    encountered              by     a user             of       the    PAIN
program.          The     two      "small        diameter"            aircraft            (small             body       and
business)         are     typical         short-haul             or     commuter              configurations.
The     relative        sizes       of    these          airplanes           can     be       Judged             quickly
from     Figures        36,     37,      and     38,      where       they        are     drawn             to    the       same
scale.


Modal       characteristics               of     each      fuselage            (cabin          and          structure)
will     determine           the    correct          way     to use          the     PAIN          program.                 Modal
spectra        will     determine           the      maximum          number         of       interior                propeller
harmonics         that       can    be    computed           and      also        the     particular                   computa-
tion     procedure           required.              The    modal        characteristics                          of    larger
aircraft         impose       more       severe          requirements               for       vigilance                on     the
part     of    a user.          Even      so,       it    will     be       found        that       there             are     no
debilitating            restrictions                even    in     the       case        of    the          largest           air-
craft       considered          herein.


4.3. I        Acoustic        Modes


The     PAIN     program        creates          400      acoustic           modes        for       use          in    the     in-
terior        noise     calculations.                    These     are       constructed                    by    combining
the     CYL2D     output        file      (resonance              frequencies                 and       mode          shapes        of
the     twenty        2-dimensional              modes       (i =       0    to     19)       of    the          cabin        of
unit     radius)        with       twenty        axial       modes          whose        index          q    (that          de-
fines       shapes      and     frequencies)               ranges           from     O    to       19       also.           The
resulting         modal       array       (or       file)     is      no.__tcomplete.




                                                           -1o5-
Consider,                for     example,                    the       computed                    acoustic                 modes              for        the     cabin

of       the        smallest               (or       business)                      aircraft                  (see          Appendix                  C).         The

lowest             resonance                frequency                    (q         =    I, i           =    O)        is     predicted                    to     be

22.1          Hz.         The        last        mode             in     the            list           (q     =    19,       i     =       19)        is       pre-

dicted              to    occur           at     about              665         Hz.            The          (q     =     19,       i       =    O)        mode

(No.           184)       occurs            at    420.5                Hz.              There           are        modes           missing                 in     the

list           (file)          above           this           frequency.                           The        first           is       the          (q     =     20,

i    =    O)       mode        at     442.6              Hz.           Since             modes              of     the        type             (q     >     19,       i    =

O)       do     not       appear,              there              are       a       number              of        modes          missing                  in     the

range           between              420.5           Hz       and        665            Hz,        but        they          are        widely              scattered.

The       (q       =     19,     i    =     I)       mode           occurs               at        436.1           Hz.           Above              this         fre-

quency,                modes         of     the          type          (q       _       19,        i    =     I)       are       missing.                      The

(19,          2)       mode      occurs              at       441.3             Hz       and           above           this         frequency                    modes

of       the       type         (q     _    19,          i    =     2)      are          not           included,                 and           so     on.         Thus

as       one       nears         the        bottom                of     the            file           (the        higher              frequencies),

there           are       more        and        more             missing                modes.



PAIN          uses        all        of     the          acoustic                   modes              in     the       list           (regardless                        of

their           resonance                  frequencies)                         to       calculate                     the       interior                  levels

for       a     given          propeller                     harmonic.                    Usually                  (and          as        has        already

been          verified               in     the          scale           model                studies)                 acoustic                 modes            that

are       resonant               close           to          the       harmonic                    frequency                  will             contribute

most          to       the     predicted                     interior                   level.                As       long         as         PAIN        has

data           for       modes        near           a       given          harmonic,                       it     can        predict                 the        in-

terior             level         using           a       (preferred)                          low        frequency                  calculation                       pro-

cedure              (that        procedure                    was        used            in        the        scale           model             studies               of

Section                3).       However,                    if     the         modal              information                      for         the         cavity

is       not        available               (or          incomplete),                          a       high        frequency                    calculation

technique                 must        be       utilized.                        That           procedure                     does          not        rely           on

the       specific               acoustic                    modal           properties.



Consider                 then        the       business                  aircraft,                       and       assume              a       blade           passage

frequency                 of     say        102          to        107      Hz.               Further              suppose                 that           results

for       the          fifth         harmonic                 will           be         sought.                   The       highest                  frequency




                                                                                  -I06-
of    concern           will      then      be     535       Hz.        The       fourth       harmonic            could         be
as    high     as       428     Hz.        It    is     seen       that       at    least          four     harmonics                can
be    computed            with       the    low       frequency              procedure             since      the      modal
list     is    complete              up    to    442.6        Hz.        The       acoustic           modal        density            is
so    great,        that        a missing             mode        or    two       (near       the     fifth        harmonic)
would        not    disallow              use    of     the       low    frequency             procedure              for       the
fifth        harmonic           also.           However           knowledge             of    the     missing          data          in
that     region           would       be    useful.               Remember          that        the       calculation
with     the       Nigh        frequency           procedure             is       always       output,           so    it       is
useful        to    obtain           the    low       frequency              result          also     whenever             possible,
even     when       the       harmonic           lies        in    a region             where        the    modal          file       is
incomplete.


Next     consider             the     intermediate                 size       fuselage              (small       body).              The
cabin        has    its       lowest        acoustic              mode       at    14.9       Hz;     the     last         mode       in
the     file       is     486     Hz.       The       file        is    complete             below        298.3       Hz.        Thus
if    the     blade        passage          frequency              is    in       the    range        of     110      Hz    or       so,
3    harmonics            can     probably            be predicted                 with       the     low     frequency
procedure.                The     fourth         should           be    computed             with     that       procedure
also     (although              it    will       be     an    incomplete                calculation),                 and       the
fifth        would        have       to    be    done        with       the       high       frequency           technique.


The     cabin        of    the       narrow        body       aircraft             has       its     lowest        acoustic
mode     at     8.2       Hz.        The    last        mode       in    the       file       is     at    297     Hz.          The
file     is     complete             below        163.3       Hz.        In       the    Propfan           configuration
with     a blade           passage           frequency             of    say       165       Hz,     only     one      harmonic
can     be    computed            with       the      low      frequency            procedure.                If      results

for     five       harmonics              are    desired,              the    remaining              four     must         be    ob-
tained        with        the     high      frequency              procedure.


4.3.2         Structural              Modes


The     modal        data        file      which        is     created            with       program         MRP      and       then
conditioned               with       MRPMOD        is    needed          for       two       purposes:             (I)      for




                                                                  -107-
calculating              the    generalized                   (or    modal)         forces        _G(r,H)                for       the
propeller           noise       excitation,                   and    (2)     for       calculating                  the    struc-
ture-interior               coupling            functions              f'(n,r).              (Note:             r is       the
structural           mode       index,          n is          the    acoustic            mode        index,          and       H    is
the    propeller           harmonic             index.)


The     structure-interior                      coupling             functions            are        needed          in    the
low     frequency          procedure.                    Calculations               with       that        procedure                are
not    possible           if    either          the       acoustic          or      the      structural                  modal
files     do       not    extend          beyond          the       harmonic           frequency               of    concern.
But    PAIN        Can    make       an       interior          prediction               even        if    the       acoustic
data     file       is    exhausted.                 It       can    bypass         the      calculation                  of
f' (n,r)       by    going        to      the       high       frequency            procedure.



The    modal        forces,          _G(r,H),             on    the       other        hand,         must       always             be
computed,           that       is,     for      use       in    either          the      low     or       the       high       fre-
quency        procedure.               Once         a harmonic             is     selected,               the       correspond-
ing    modal        forces        (for         all       modes)        must       be     computed.                  Although
the     entire       file       is     utilized,               it    is    important             that          the       file       ex-
tend     beyond          the    frequency                of    the     harmonic           being           calculated.
This     is    required           because             structural            modes         resonant              in       a fairly
wide     region          centered             about       the       harmonic           will      (likely)                contribute
most     to    the       interior             levels.            (This       was       found         to    be       true       in       the

scale-model              predictions                of    Appendix           B.)


ANOPP     ImDosed          Limitations


The     accuracy          of    the       NASA        ANOPP         propeller            noise        prediction                   pro-
gram     (or       any    other        comparable               program)            is     suspect             beyond          the
fourth        or    fifth       harmonic.                 ANOPP        should          not      be    used          to    create

input      data      for       PAIN       beyond          the       fourth        or     fifth        propeller                har-
monic.         This       is    not       a    critical             deficiency.                The        highest          ex-
terior        levels        will       be      in     the      lowest         few      harmonics               and       the       atten-
uation        afforded          by     the      structure              will       be     lowest           at    the       bottom




                                                               -108-
end of           the       frequency             spectrum           also.            This        means that                   the     capa-
bilities              of       the    PAIN program                 can be reasonably                           examined              in
terms        of       computing,                say    a maximum of                  five        interior                harmonics.


Program              Changes          to MRPMOD


The     sizes             of    the       fuselage        cylinders              of       concern              in    Table           13
suggest              that       a software             modification                  be     made        to      enhance              the
potential                 utility          and    completeness                 of     the        structural                   modal
file,        i.e.,             to    extend       it    to     as    high        a    frequency                 as       is    practi-
cal.         To       this          end,    before        beginning              any        computations,                      the
MRPMOD           program             is    modified           to    accept           an     increased                eigenvector
output           from          the    program          MRP,        i.e.,       40     eigenvectors                       (20    symme-
tric       and        20 antisymmetric)                      instead           of     thirty.              A    total          of     440
structural                 modes          can    then     be       predicted              with        an       allowable              range
of    axial           mode          numbers       M    from        I to     11.       The        number             of    axial           half-

waves        M       is    limited          to    11 because              a maximum               of       450       modes           can
be    used           by    PAIN       (12"40=480"450).                    The        structural                 program             MRP
itself           need          not    be    changed           since       it     can        be    made          to       compute
all     of       the       modes          required        simply          by     specifying                    the       maximum
value        of       M    and       the    number        of       eigenvectors                  desired.                 However,
"Dimension"                    statements             must     be    changed              in     MRPMOD             to    allow           it
accept           the       MRP       output.           Because        of       the        increased                 size,       the

new     output             file       from       MRPMOD        (that        to       be     used        by      PAIN)          must
become           a    direct          access          instead        of     an       indirect              access             perma-
nent       file.               This       requires        some       changes              in     the       control             state-

ments        for          MRPMOD          and    PAIN     (see       Appendix               A    for       more          details).


Ty_i cal             Results


The     lowest             structural             mode        of    the     fuselage               cylinder               of        the
business              aircraft             of    Table        13 is        predicted               to      occur          at    39.6           Hz

and     is       given          in    the       "Structural           Modes"              list        that          is    output
by     the       PAIN          program          and    which        summarizes                  the     MRPMOD            output           file




                                                               -109-
(Appendix   C).   The last  mode in                                       the      file,  i.e.,                the 400th mode
in this   case (since   M is limited                                        to      10 for the                present)  is
predicted             to      occur          at      2054 Hz.             The corresponding                        results             for
the     small         body           aircraft            are     23.5      Hz and                1414 Hz and for                the
narrow            body aircraft                    13.1     Hz and 823 Hz respectively.


The predicted    fundamental                                resonance              frequencies               here are con-
sidered   reasonable.    For                              instance,              the narrow                body fuselage
cylinder            is a large                  aeronautical  structure                                by almost    any
measure            (23m(75 ft)                  long by 3.75m(12.3      ft)                            in diameter)     and
it     is     quite         stiff.              A comparable                 structure                 once      considered                 in
noise         studies    was the payload   bay door of the space shuttle
orbiter          vehicle   (4.87m diameter   by 18.3m long).   Analyzed  by
elaborate                finite         element            techniques,                 it        was found         to have              a
fundamental                 resonance                frequency            of     7.4         Hz (modeled               as an in-
complete  cylinder   (or sector)  supported     on its   edges).                                                                   Also
the bottom structure     of the shuttle   vehicle     (a stiffened                                                                  curved
panel)            similarly             analyzed            had a fundamental                            resonance           frequency
of 9.6            Hz.


The         question          is       now      raised         as    to      whether              the     structural               modal
files         are        complete            over        typical          required                 frequency           ranges.               Air-
craft         in     the         turbo-prop              configuration                      will       typically         have           the
 fifth        harmonic               below         about       550      Hz.           In     the       Propfan         configuration
this         upper         frequency               could       become          825          Hz    or     more.         The     main
question             is     whether             a reliable              prediction                  of    modal        forces           can           be
made         up     to     these        frequencies.


â€¢The        structural               modal         file     is      much       more          difficult            to    analyze                  in
 terms        of     determining                   its     completeness.                         This     is     because           the           fuse-
 lage        cylinder             is    so        complicated.                 The          modal        behavior         of       a    stiff-
 ened        cylinder             with       floor         partition              is        much       more      difficult              to        de-
 scribe           than       a    stiffened               cylinder           without               floor       _Ref.         I).        As        one

 examines            the         output         of    MRPMOD,           it       is     found          that      for    many           modes




                                                                     -110-
of    a given           axial          mode     index        M,      the     same         shell        indexes             n s will
appear        (n s defines               the        number        of      full       circumferential                       waves
of    a given           component              of    the     displacement                  series           used       to       de-
scribe        the       shell          circumferential                    mode       shape).            Also,          the       same

indexes   np (giving                     the        number   of transverse                    halfwaves   of a
given   component  of                    the        displacement    series                   used  to describe
the     transverse                floor        mode       shape)          may     appear          as    well.              But

each     structural                mode       is     unique.              Each       has    its        own       set       of    gen-
eralized           coordinates                 that       ultimately              define          the       particular
mode     shape.              Each       has     its       own     generalized               mass.            Some          of    the

modes        are       predominantly                 floor        modes,         others           predominantly
shell        modes.


Business           Aircraft



The    modal           file       for    the        business           aircraft            (PAIN        summary             in       Appen-
dix     C)    shows          that       the     maximum           value         of    M    (i.e.,           M=IO)          occurs
the     first          time       at    the     40th        mode       (227.7         Hz).         It       therefore                seems
logical           to    assume          that        a mode        with       index         M=11        will       occur          soon

afterward              and     that      somewhere              in     the      range       slightly              above          227.7
Hz    the     file       must          become        incomplete              (since         M=11        is       excluded).
Close        examination,                however,            shows         that       the     first          M=IO          mode       is     a
floor        mode.           Almost        all       of     the      energy          of    the     mode          is    in       flexural

motion        of       the     floor.           This        can      be    recognized              by       examining                the
generalized              mass.           The        shell       flexure,             w,    contributes                 little          to
the     total          modal       mass        (about        2%).          Since          this     mode          will       not       re-

spond        well       to     the      propelIer            excitation               of    the        sidewall,                it    is
somewhat           an    extraneous                 mode    (even          though          listed)           and       a    compara-
ble    mode        with        M=11      would        be     also.


The     adequacy             of    the     file        (in      the       sense       of    completeness)                       is    as-

sured        if    when        either         M,     n s,    or      np    reach          their        maximum             values
(in     this       case        M=IO,      ns=14,            and      np=5)       the       mode        is    a    genuine             shell




                                                             -111-
mode or           at least             has     some significant                               flexural           energy           in     the
shell.           Going           down the           file,          it        is        seen that               the     second          time
M=IO appears is at the                              48th mode (250.5  Hz) where the shell
flexural modal mass is                              but 0,2% of the total.   M=IO occurs
again          at the       72nd mode (363.4                            Hz)        where           the      shell       flexural
modal          mass has           risen        to      about            24% of              the     total        generalized
mass.           Somewhere slightly                        above this frequency,                                    there  will                 be-
gin to          be some modes of                       the type M=11 missing                                    that   should                le-
gitimately                be in        the     file.           Note               that        by the           147th        mode (at
579.4         Hz),        where        the     M=IO index                    once           again        appears,            the       shell
modal          mass is           89% of the total                        generalized                     mass.


There          are    8 modes           between             the         72rid and                 147th        modes        having           M=IO,
all      of     which       have        significant                     percentages                   of       their        energy           in
shell          flexure.               There        will       be        less           than        8 missing            modes          of     the
type       M=11       below           550     Hz    (which              is        the       maximum            frequency            of       con-
cern       for       the    business               aircraft).                      Within           a band           about         100       Hz

wide       centered              at    550     Hz,       there           are           29     modes         (Modes          124     through
152).           There       are        four        modes       with           M=IO.                Thus        there        will       be     less
than       four       modes           with     M=11         missing                over        this         range       and       fewer

still          with       M=12        (perhaps           none).                   It     is       clear        that     even        though

the      file        is    incomplete,                 if     the        primary               contributing                  modes           to    the
interior             noise        are       selected           (by           the         program)              out     of    those           lying
50    Hz       either        side       of     the       harmonic                  (assumed               at    550     Hz),        there          is

only       a    small        chance           that       an    M=11               mode        will        appear        as    one        of       the
top      five        contributors                  and      only         a miniscule                      chance        that        it       will

be     the      dominant              contributor.                   Thus,               in       this      case,       since          n s and

np are well below  their maximum    values                                                     (i.e.,  in the range   be-
low 600 Hz or so), the modal    file   can                                                    be considered  sufficiently
complete.


This       file       can        be    made        complete              by        including                significant                 flexural
(shell.)          modes          of    the     type         M=11         for           frequencies               below        say           650    or
700      Hz.         Its    length            can      also        be        optimized                if       when     M    is     increased




                                                                   -112-
to     11,    the       maximum           values           of     n s and          np      are        reduced              to     8    and           4
respectively.                   These           values           are       chosen          by     examining                 the        printed
output        of     MRPMOD          where           (in       the     present             case)           the        5 terms              used
in     the    shell          displacement                   series           (i.e.,             the    ns'S)           and        the        3

terms        used       in     the     floor          displacement                     series           (i.e.,             the        np's)
and     which        are       passed           to    PAIN           and     used        to      construct                 the        mode

shape,        lie        below       the        maximums               selected.                 The       number            of       eigen-
vectors           computed           by        MRP     should           remain             at    40     if       this        is       done.


Small        Body        Aircraft


Similar           results           are        found           for     the      small           body        aircraft.                  Scanning
the     M=IO        modes        leads          to     the       following               results.                    The        first           is       the
18th        mode        (41.4       Hz)        with        shell        flexural                modal          mass        representing

0.04%        of     the       total        generalized                  mass.              The        second          is        No.        21    (42.5
Hz)     and       0.9%.          Then          No.        40    (111.0          Hz)        and     0.35%;             No.        48        (118.1

Hz)     and        5.1%;       No.        80     (206.8          Hz)       and        7.7%;        No.          92    (225.6            Hz)          and
 13.7%;        No.       124     (296.6           Hz)          and     51.5%;           No.       125          (298.3           Hz)        and       82.4%;

and     so     on,        In     these           cases          n s is       below          its        maximum              of        14    (never

exceeding   ns=8 passed                           to PAIN) _d   np                         is 5 or less  (it reaches
its allowed    limit).                           Here it is clear                          that the M=11  modes  should

be     in     the       file     beginning                 at     about          300       Hz.


 To    complete              this     file,           the       maximum            value          of       M    must        be       increased,
 but     to    no       more     than           15    (the        maximum             allowed).                  It        is    necessary

 to     simultaneously                    reduce           the        number          of      eigenvectors                      computed                  by

 MRP (Changing   n s or np                            is irrelevant).                       Thus               40 eigenvectors     can
 be computed   if M=I I is                            sufficient   to                   complete                the file   (40.11=
440<450),               but     only        36       if    M=12        is       required              (36-.12=432<450)                           and       34
 if    M=13        is     needed          (34-13=442),                     32    if     M=14          is       necessary               and           30    if
 M=15        must       be     used.            The       object           is    to     assure             that        there           are           few

 (if     any)        missing           shell          modes           of     the      highest              M    selected               below
 about        650       to     700     Hz       (i.e.,           if     five       harmonics                   are     to       be     computed).
 All     modes          having         the       maximum              selected             value           of    M     with           more           than




                                                                       -113-
50%      of       their       modal          mass          in    shell        flexure             should           lie       50    Hz     or
so      above          the    frequency                of       the    highest           harmonic              to     be       computed
with        PAIN.


Narrow            Body       Aircraft


The      narrow          body          aircraft             has       its     first          M=IO        mode        at      35_2        Hz
(mode         No.       12).           The       fifth          M=IO     mode          occurs        at       159.9          Hz     (mode
No.      94)       and       is    the       first          true       M=IO        shell          mode        (shell           flexural
modal         mass=73%             of       total).              Therefore              the       modal        file          begins           to
be      incomplete                at    a    frequency                well        below        550       Hz    and        very       much
below         825       Hz.        In       the       case       of     the       narrow          body        it     is       concluded
that        the        maximum          value          M=15       may        be    required              (reducing                 the
number            of    eigenvectors                   computed              by    MRP       to     a total             of     30).


The      maximum             frequency                of    a harmonic                 attempted              with        PAIN       should
not      exceed          the       frequency                where        the       highest           M    mode          type        has
more         than       say       50%       of    its       modal        energy           in      the     cylinder                 flexural
response.                Above          that          frequency,              the       structural                 modal           file
used        by     PAIN       is       insufficientl_                    complete.                  This       will           probably
limit         PAIN       to       3 harmonics                   (perhaps           4).         While          a computation
 cam     still          be    made          that       will       yield           an    answer           for       the _ fourth
harmonic               (since          the       incomplete              file          extends           out       to     823       Hz),       the
 result           will       be    questionable.


Now      as M is             increased                and       the     number          of     eigenvectors                    reduced,
 there        will        begin         to       be    some       modes           of    low       order        M     missing             from
the         file.         For      example,                when        the    maximum             value         of      M is        used       and
 only        30    eigenvectors                   can       be     computed,              there          will        be       30    modes
 listed           for     each         value          of    M.         The    30th        mode       in       the        file       for       any
    given     M    will        have         the       highest           frequency              of    any        mode          of    type       M.
 Beyond           that        frequency               there        will       be       modes        missing              of    that        type
 M.

    !

j




                                                                        -114-
In    the     present             narrow         body           case        (where           M is     limited                to     10)     there
are 40 eigenvectors  or 40 modes listed for each value  of M.
Consider  the M=I modes.  The 40th mode v_th M=I occurs   at 618.3
Ez    and     has       a major               circumferential                        component               ns=11        (11       full
circumferential                     waves).                Above        618.3           Hz    there           are     modes          missing

of    the     type         M=I.          Had        the     number              of    eigenvectors                   been         limited
to    30,     the       last        M=I        mode        would           have       been      at       432       Hz.        To     complete
the    M=I        modes        out       beyond            the       third           harmonic            (3x165=_95                Ez),         36

eigenvectors                  are       needed         (the          36th        M=I     mode        occurs             at    503        Hz).
Thus        the       maximum           value         of    M    would           be     limited              to    12.        This         might

not     be    optimum             however.                 It    may        be       necessary               to    increase              the
maximum           M    and     allow           some        modes           of    low     order           M    to     be      missing.
Each        case       will        warrant            an       investigation.


4.4         ComDutation                 Times


The     central         _ processor                 unit        (CPU)           times        for     typical              fuselages              are

given        in       Table        14.         These           are     for        the    Control              Data        Corporation
(CDC)        CYB_ET                Network            operating                 System         (NOS)           176       service           (es-

sentially              the        computer            speed           is    comparable               to       (but        faster           than)
the     CDC        6600       vintage            computer).                     CPU     time        is       a resultant                  of    pro-
cessing            periods           and       is     not       clock           time.          CPU       times          will        Vary        from
computer              to    computer             depending                 upon        speed        and        program             handling.
It     is    a useful              measure            for        comparing              speed         and         costs           from     compu-

ter     to        computer              and     for       estimating                 costs      and          practicality                  on    a
particular                 machine.


The     most          time        consuming               is     the       structural               calculation.                     The        pro-

gram        MRP       runs        all     fuselages               at       about        the     same           speed,             regardless
of     the        dimensions              (or       stiffnesses)                     concerned.                   For     large           numbers
of     modes,           the       run-times               increase              almost         in     direct             proportion                  to
the     increase              in        the     number           of    computed               modes.              For     instance,
 calculation                 of     a    total        of       300     symmetric               and       antisymmetric                     modes

 of    the        scale       model            fuselage           required               1506        secs.           When          400     modes




                                                                     -11 -
             Table   14.      Program         Run-Times        (Typical)



    Pro gram               Calculation                                                  CPU Time
                                                                                         (Secs.)


    CYL2D            Floor     angle      =    56.6 Â°                                      119

    MRP              150     symmetric         modes                                       795
O

                     150     antisymmetric             modes                               711

    MRPMOD           300     structural         modes                                       66

    PAIN             400     acoustic/300             structural(4Hlf/6Hhf)                249


    CYL2D            Floor     angle      =    50.0 Â°                                      197

m   MRP              200     symmetric         modes                                      1087

                     200     amtisymmetric             modes                              1043
m   MRPMOD           400     structural          modes                                      91
m   PAIN             Modal     summary/400             acoustic/400        structural       82

                     400     acoustic/400             structural(3Hlf/7Hhf)                340


    CYL2D            Floor     angle      =    62.6    o                                   157

    MRP              200     symmetric         modes                                      1049
O                    200     antisymmetric             modes                               965

    MRPMOD           400     structural          modes                                      90

    PAIN             Modal     summary/400             acoustic/400        structural       95

                     400     acoustic/400             structural(3Hlf/2Hhf)                300

                     400     acoustic/450             structural(3Hlf/2Hlf)                500


    CYL2D            Floor     angle      =    73.7 Â°                                       70

o   MRP              200     symmetric         modes                                      1040

                     200     antisymmetric             modes                               940
O
    MRPMOD           400     structural          modes                                      91
    PAIN             Modal     summary/400             acoustic/400        structural      106
Z
                     400     acoustic/400             structural(IHlf/3Hhf)                300




                                              -116-
were     computed              for      each        of     the        three         aircraft           fuselages,            the
average           CPU    time        was          2041     secs.            Thus      33%       more      modes        required
an    average           of     35%      more        computation                 time.           Therefore            it     is     an-
ticipated            that         for     a case           where          450       modes        are     computed           (the
maximum           number          that       PAIN         will        work      with),           about        2300     CPU

seconds           will       be     required.


A    complete           calculation                 with        PAIN        for      the     scale-model               fuselage,
utilizing            400       acoustic             modes           and     300      structural               modes        (where
10 interior               harmonics                (H)     were        calculated;                4    with      the       low     fre-

quency        (lf)        scheme             and    6 with            the      high        frequency           (hf)        proce-
dure)        required             249        secs.


Calculation               of      10 interior                  harmonics              for       the     typical        business
aircraft            using         400        (instead            of    300)         structural            modes        required
340     secs.           82     seconds             were        needed          to     complete           the     calculation
through           the     output             of    the     modal          summary.               The    remaining            time
was     used      _in     calculating                    the    modal          forces           for     the    propeller
noise        field        and       the       interior              levels          (3     harmonics           were        calcu-

lated        with        the      (slower)               low     frequency               procedure).


In     the     case       of      the        small        body        aircraft,             a maximum            of    3 interior
harmonics            can       be     computed             with        the      low        frequency           procedure.                 5
interior            harmonics                (2 using            the      hf    procedure)               required           approxi-
mately         300       secs.


There        is     a practical                   limit        of     4 interior                harmonics            for    the     case
of     a narrow           body        aircraft              (Propfan              configuration).                     Only       one
can     be     obtained              with         the     low       frequency              technique.                The     CPU    time
should         be    less         than        300        secs.


In     the     extreme            case,           where        say     5 interior                harmonics            are     desired
(3     to    be     calculated                with        the       low      frequency            procedure),                and
where        the     number             of    structural               modes          is    the        allowed        maximum            of

450,        the     CPU      time        for       PAIN        is     expected             to    be     less     than        about
500     secs.

                                                                 -117-
5.0     FLIGHT TEST COMPARISONS


Flight   tests             were performed     on a trimmed and outfitted       Merlin
IVC aircraft               (corporate   version   of the Fairchild    Industries
Swearingen Metroliner                           III     turboprop  commuter aircraft).     The
Merlin  IVC is identical                              to the business  aircraft   shown in
Figures        36 and 40 and the                         fuselage             construction                  is     basically
as showa in               Figure          41 and as detailed                        in     Table           13.


5.1      Description                 of    Aircraft


The    Merlin         IVC       has       twin        Garrett           TPE331          turboprop                engines

driving        Dowty        Rotol          four-blade               constant              speed          propellers.
The    propeller            diameter              is     2.69       m    with       a tip           clearance            of
about        0.06     times          the    propeller               diameter.                  The       fuselage            is
am    all     metal        cylindrical                  semi-monocoque,                    pressurized                  fail-
safe     structure              of    2024        aluminum              alloy       having            a diameter              of
1.68 m.


The     cabin        of    the       aircraft            used       in       the    tests           is     shown        in    Fig-

ure     42.      A bulkhead                located            at    Station              126       separates            the

crew      flight          deck       from       the      forward             end    of        the     cabin        amd       the
aft     end     of    the       cabin       terminates                  at    Station              437     where        a bulk-
head      (with       door)          closes            off    the       rear       baggage            compartment.


The     interior           of    the       cabin         is     trimmed            with        0.05        m     (2 inches)
of    PF-I05         Fiberglas             in     mylar         bags         with        a headliner               of     3.2       mm
(I/8     inch)        thick          heat-formable                  Klegecell                 with       two      glass       face
sheets        of Tedlar.                  The         trim    surface           mass          is     1.95        kg/m 2      (0.4
lb/ft2).             A relatively                     small     portion            of     the       interior            trim
surface         is    covered             with         decorative             Teak        wood        (less         than          10%)
and     is    not     felt       to       warrant            consideration                    in     the       modeling            .


The     aircraft           tested          has         leather          upholstered                  seating         for       eight
passengers            in     the      mid        and      aft      sections              of    the       cabin       plus          a



                                                                -118-
 ORIGI?_#L   PAG_
 OF POOF_ QUA Lt'V'_"




                                     k_
                                     Z

        qP
                                     <


                                           z


                                     0<
                                     Z_J
                                     _0
                                     I--.-1
                                     U-I.W
                                     <Z

                                     _"r"




                                     <Z


                                     N

                                     I,I



                            "   ,4   m
                                     U..
                        m       m




-119-
couch        (sofa)           of    about        I meter              length        located             in    the       forward
end    of     the    cabin.                In    addition,               food       and     beverage               storage           and

preparation               facilities                 are       present         in    the        forward            end.


The    seating            structure              dead          weight         on    the       floor          spread        over
Stations           264-437           is        about        12.2       kg/m 2.           This        same      weight           spread
over     the       entire           length           of     the       cabin        gives        6.8      kg/m 2.           An    aver-

age    of     these           is    9.5        kg/m 2 which              is       assumed          to    be    a representa-
tive     distributed                 mass.            The        mass     per       unit        of      area       of     the    floor
                         -\


used     as       an input            to       MRP    is       then      9.5       kg/m 2 plus               the    weight           of
the     floor       and         supporting                floor        structure,               i.e.,         about        4.2       kg/m 2
(Table        13) yielding                     a total           of     13.7       kg/m 2.           This      number           is    very
close        to    the         result          used       in     the     studies           of      Section          4 (and           Table

13)     so    the     structural                 modal           file        for    the       business             aircraft
given        in    Appendix               C is       identical               to    that       of     the      present           test
aircraft.


The     surface           area        of       cabin        sidewall              trim     (floor-to-floor)                      is

given        by



                               A t = 2_rLc(a-h t) (I-8o/180)




where        8Â° is            the    floor        angle          (500),           a is     the       fuselage             radius
(0.84        m),    L c is           the       cabin        length           (7.89       m)     and      h t is          the     trim
insulation           thickness   (0.055                          m).      In the present                      case A t is
28.1 m 2.           All absorption    in                         the     cabin  space is                     assumed  on the
sidewall.             The           forward           and       aft     bulkheads             are       taken        rigid        and
unabsorbing.                    This       is     a    simplification                     because            they        do    absorb
and     transmit               sound.           Also        it     was       determined               after         the       tests
that        the    door         to       the    baggage            compartment                had       been       inadvertently
left     open       in         flight.


The     absorption                  by    the        seating           and     carpets          is       assumed           to    have
negligible            influence                  on       the     interior           sound           levels         in     the       range


                                                                   - 120-
between           100 and 550 Hz.                      This        assumption                can be justified                          by
examining              the     relative           absorption                capabilities                    of    the        sidewall
trim     system          versus           that     of       the       seating.               For       instance,              at
500     Hz,       the    absorption               of    a typical                upholstered                 seat          would        be
limited           to    about        3 Sabins           (aS=3          ft 2 or         0.28        m2).           8    seats

plus     the       couch        would        give,          say       27    Sabins,           or       an    absorption                 of
2.5     m 2.       The       PAIN      computed             conductance                _ of        the       sidewall              trim

for     a lightly              damped        trim       panel,             say    _T=0.2,              at    500       Hz,        is
0.017        and for a heavily   damped  trim panel,                                           say _T=2,                   it is
0.027        at 500 Hz.   The absorption   afforded                                           by sidewall                    trim
is     therefore              at a     minimum


                                            aS    =    8(A       t = 3.8          m2



or     approximately                 41     Sabins.              Now       it    is    seen        from          these        numbers
that     the       seating           could        conceivably                   lead     to       a slight             reduction
in     space-average                 interior           levels.                 However,           in       the       present
case,        the       seating         is    located             in    the       aft     two-thirds                   of     the
cabin        (except           for     the       couch)          and       in    that        region,             as    will        be
shown        in    the        flight        test       data,          the       sound        pressure             levels           are
significantly                  lower        than       in     the      forward           third          of       the       cabin.
Thus     the       absorption               in    the       forward             third        of    the       cabin           is    of
more     concern              since       total        absorption                is     the       product             of     mean
square         pressure             times        aS.        In     the      forward           third          there           is    the
couch        (approximately                      3 Sabins)             plus       carpeting                 (ignored)              plus
sidewall           trim        (approximately                    41/3=13.7             Sabins).                  Thus        seating
should         reduce          interior           levels           by less            than         I dB      (on        the       space
average)           although            the       actual          reduction             may        be    slightly              more
in     the     area      where         seating          is       located.


5.2      Test          Program


The     measurement                 program           consisted             of    both        ground             and       flight
tests.            The        primary        purpose           of      the       ground        tests          was        to    obtain

some     minimal              data     outside          the        aircraft             so    that          ANOPP          predic-


                                                                   -121-
tions        of    the        propeller              noise        field       could          be       compared              to    meas-
urements.               No     attempt              was     made       to    instrument                the        aircraft             to

allow        in-flight              measurements                  of    the       propeller                field        on       the
fuselage.                This        was       an    unavoidable               deficiency                  in     the       flight
tests        due     largely              to    tha       status        of    the        aircraft               and     the
limited           time        that        the       plane        could       be     dedicated                to       the     effort.

Moreover,            ANOPP           is    unable           to    predict           the         actual          blocked           pres-
sure        field        on    the        skin       anyway         (it      calculates                 free-field                levels

as    previously               noted),              and     therefore             it     seemed            that        for       the

present           tests,           some        relative           measure           of      comparisons                 on       the
ground           would        be     sufficient.                  The       quality             of    _TOPP           free       field
wredictions               had        already          been         established                  (such        as       through
the     scale-model                  comparisons                 presented             in       Section           3    of     this
report).


There        were        a number              of     different             stationary                ground           tests         that
were        performedwhile                      varying            propeller             speed,             torque           (pitch),
with        one     prop        or     the       other.                However,             comparisons                  between

exterior           measurements                     and     exterior           predictions                   were       never
attempted            because              the       _0PP         program          was       unable           to       predict
the     propeller              harmonics               v_thout           significant                  air       inflow           velocity
to     the       prop     disk.            Thus        for       all     practical               purposes,               the      only
useful           data     were        the       interior            measurements                     made       in-flight              dur-
ing     the       test        runs        listed          in     Table        15.


The     in, flight              data       obtained              during        Runs         2    and       8 were           all      from
fixed        microphone               measurements.                      Sound         pressure              levels           were
recorded            at    head        (ear)          levels         _th        six       microphones                   (I     through
6)     as    sho_,rn in            Figure           42.        These        measurement                 data          cannot       be

used        in    the     comparisons                  because           space-average                     interior              levels
are     reauired              and     the       five        microphones                in       the     cabin          (2     through
6)    were        not     located              to    provide           that       particular                 measurement.
The     comparison                 data        were       taken        in    Runs        10,         11,     and        12.       In

these        three        runs,           the       airspeed           was     varied            (at        the       same       flight
altitude)            and        swept          microphone              data       were          taken           at    various



                                                                   -122-
                       0   cO




         .,-lEo




 CQ

 Q)             0




         XO




 Q)
,-,,4

                I
         n_      0
         =       ,--




                                            cO



                                             II

          _,_                   /

          =m
        ._=




                                    -123-
axial        positions          along        the       cabin.        The objective                 was to            be
able to calculate the space average interior      levels     for five
harmonics at each of the three  flight  conditions       providing    a
data pool of 15 measurements   for comparisons    with PAIN pre-
dictions.   In order to obtain   the desired   measurements,      swept
data were to be taken at a minimum of three      axial  stations.
Two of the stations   eventually selected                                          are shown in Figure                           42,
i.e., locations   7 and 8 (in the aisles                                          between the seats),
where        microphones            5 and 6 were                   swept        by hand         following             the
scheme shown in                 Figure           43.


During        the    flight         tests,            there        were     no swept            measurements                made
in     the    forward         third        of     the       cabin.          The presence                of      the       couch
and cabinetry              in      the     forward            endl did          not     allow      the       flight
personnel           to    follow          the     desired           sweeping            pattern         and a decision
was made by them to                       obtain         swept         data      only     at      positions               7 and 8
and to retain fixed microphone                                     data at positions     2, 3, and 4 as
had been done in Runs 2 and 8.                                      This  decision   necessitates  the
use of a rather    cumbersome analytical                                      approach    to               obtain          the
space-average   levels  in the cabin.                                       The propeller                  noise          peaks
over the forward                  third    of the                 cabin,  and the highest  interior
levels  occur in                that    region.                   Any errors  made in estimating
space-average              sound          pressure            levels        in     the     forward           third         of     the
cabin        are     strongly            reflected            in     estimates            of    the      total        space-
average         levels.


5.2.    I     Interior          Measurements


To     review,       the      data        consist           of     two     basic        types      of      measurements:
(I)     fixed       position            microphone                data     at    the     head      (or       ear)         level        at

up     to    five    locations             in      the      cabin        (microphone              I was         in    the       crew
flight        deck       area)      and         (2)    swept        microphone             data       at     two      fixed
axial        stations.             In     Run     Nos.        2    and     8,    all     microphones                 were       fixed
at     the    head       (ear)      level.             In     Run    Nos.        10,     11,      and      12    microphones
2,     3,    and    4 were         fixed         at    the        head     (ear)        level      (in       the      same        posi-



                                                              -124-
                                       ORIGINAL    PAGE 19
                                       OF POOR    QUALITY




                                                               \




                        II




FIGURE   43.   MICROPHONE      SWEEP   PATH     FOR
               SPACE AVERAGE   (ABOUT         15 SEC/CIRCUIT
               TRAVERSED  TWICE)




                             -_25-
tions       as    in     Runs        2 and         8)    and        microphones                5     and       6 _were         swept     at

positions           7    and       8.        In    these         latter               tests,       no     fixed       head        (ear)
level       measurements                    were     made        with         microphone                  5 or       6.


The     cabin       can       be     divided            into        3    subvolumes:                 Stations             126-230,

230-333,           and       333-437.              The     swept             microphone              measurement                taken
at    position           7    (with          microphone                 5)    is       considered              to    give       the
space       average           level          in    Subvolume                 2    (230-333)              and    the       swept
measurement              taken          at    position              8    (with             microphone           6)    is       con-
sidered           to give          the       same       data        for          Subvolume           3    (333-437).
Measurements                 made       with       microphones                    2    and     3   (which           lie    in     Sub-
volume           I (126-230))                are     averaged                to       determine           an    average           head

(ear)       level        N_     for         each     harmonic.                    Also,        measurements                with

head     (ear)          level        microphones                   4 and          5 which          lie     in       Subvolume           2
in    Run       Nos.     2 and          8    are     averaged                to       determine           an    average           head

(ear)       level        for       each       harmonic,                 i.e.,          _.


In    summary,           let


        _=mean           head        (ear)         level           measurement                 for       those       microphones
                located         in      Subvolume              j    (harmonic                H),     i.e.,




                                     _jH           101ogI(I/N)                   _I0        SPLH/IO        1
                                              =
                                                                             ieJ



and     also       let

            t7

         s_=space             average              (swept)          level             measurement              made       in    Sub-
            W


                  volume        j    (harmonic              H)


The     available             measurements                  are         then          as    given        below




                                                                   -126-
                                         Microphone                Locations           and Usage
                I



         Subvolume,                  j                 Run      Nos.                          Microphones_               i
                                                                                             Head   (ear)             Swept

                    I                               2,8,10,11,12                                   2,3                     -
                    2                                          2,8                                 4,5                     -
                    2                                  10,11,12                                      4                     5
                    3                                          2,8                                   6                     -
                    3                                  10,11,12                                      -                     6


Table      16       summarizes                 all     of      the       pertinent           interior           flight          meas-

urements.                Figure           44     shows         one       of    the     interior           spectrum             of    the
type     from           which        the       data       in    the       table        were       taken.         The       table
contains            the      measurements                   and      also       the     calculated              mean       head

(ear)     level_             where         such        a calculation                   is    meaningful.                Note
that     the        highes_              levels        in      the       aircraft           occur        in    Subvolume             I
(which      the          propeller               plane         passes          through)           and     thus       the       space-

average         interior                 level       in     the      cabin       will        be     dominated           by      the
space-average                   level          in    the       forward-most                 subvolume.               Unfortunate-

ly,     there           is   no      direct          way       of    determining                 a relationship                 between
the     measured             (average)               head          (or    ear)       level        and     the     space-average
level     so        the      latter            must       be       estimated.               Also     note       that       there          is
a   considerable                  decrease             in      sound          levels        from     the       forward          to       the

aft     subvolume.                   This        makes         an accurate              estimation              of     the      space-
average         level           in       the     forward            subvolume           even       more        critical.


5.2.2       $cace-Average                        Levels


The     mean        difference                 can     be      calculated              between           the    mean       head
levels      in          Subvolumes               I and         2    for       Runs     2 and        8,    i.e.,




For     Runs        10,      11,         and     12,      there          can    also        be    calculated            the         mean
difference

                                                 <, IH-sH>Io,            11& 12               ,




                                                                     -127-
                              Table     16.     Interior       Measurements




Run       #2     V =192       kt,     Alt.=17,500       ft

                                               Head   (Ear)     Levels




      I        102.2      102.4             95.5      103.8        102.3        101.4           98.4
      2         99.0      100.0             98.2        84.8        99.5         95.4           87.5

      3         94.2          95.6          80.5        82.0        94.9         81.3           82.0
      4         81.5          76.3          67.0        65.8        79.6         66.4           66.7
      5         69.0          76.3          69'0        68.2        74.0         68.6           63.0


Run       #8     V =210       kt T Alt.=12,000          ft

                                               Head    (Ear)    Levels




      I        100.6       101.7             96.7      102.0       101.2        100.1           97.0
      2         98.4          97.8           96.5       80.5        98.1         93.6           84.5
      3         90.6          95.5           76.7       78.1        93.7           77.5         79.8
      4         66.6          71.0           66.0       66.2        69.3         66.1           65.0
      5         72.0          75.0           64.0       69.5        73.8           67.5         66.7


Run       #10     V    =238    kt I Alt.=5,000          ft

                        Head        (Ear)   Levels                         swept


      H        SFL_       SPL_                 H      SPL_          H
                                                                   s2=SFLâ€¢ H7      s_=SPL_

      I        104.4       102.5            103.6       95.8          102.0             99.5
      2         98.8       103.2            IOI .5      98.8             90.2           82.0
      3         92.5          99.7           94.5       82.6             80.8           78.8
      4         80.2          82.0           81.2       72.0             73.2           68. I
      5         72.2          76.7           75.0       63.0             70.7           67.3




                                                      -128-
             Table       16.    Interior     Measurements    (Continued)




Run          V   =216     kt I Alt,=5,000       ft

       ' â€¢        Head     (Ear)   Levels                     Swept
                   I




  H s_                 _,._         _         _P_ s2_-s_
                                                   7_ _ s_-s,_
   I   101.7            102.0      101.9       96.7         97.6         97.7
  2       96.6           99.0       98.0       94.4         88.8         79.5
  3       90.5           96.2       94.2       80.8         79:2         75- I
  4       70.5           77.0       74.9        71.4        71.7         64.5
  5       72.7           77.2       75-5       59.0         67.8         64.0


Run #12      V   =165     kt,   Alt,=_,000      ft

                  Head     (Ear)   Levels                     Swept


  H    SPL_            SPL_          _        SPL_      s_=SPL_       s_=SPL_

  I       97.8           95.6       96.8       92.7         93.8         96.2
  2       94.2           91.7       93. I      92.3         87.0         76. I
  3       89.4          91.4        90.5       75.4         75.2         67.9
  4       73.5           76.8       75.5       69.5         67.0         60.5
  5       68.8           72.0       70.7       58.0         63.2         60.0




                                             -129-
                                   ,jRIGINAL PAGE 1"
                                   OF poOR QUALr_




            N        L_
            -|

                                                                                      Â¢1




                                                                                     uL




                                                                                           t--

                                                                                           ,q:
                                                               q,




                                           t'l"l

                                                                                           m
                                                                                           i1
                 N




                                                                                 0



I   !   I                   !        I             I       !        I    !   I



                          md ff 0_ a,_ _lP 'l_31       _dASS_dd OMflOS




                                                       -13o-
where   s_ is the space                             average           level  in Subvolume                         2 (swept   meas-
urement   with microphone                              5).           Table  17 shows   the                       results   of the
calculations.                    There          are        a number               of    different               things           to    be
noted.         First,            all       runs        are       for            the    same        propeller              speed        (Table

15).        From       a    frequency                 selection                  standpoint,               this       means           that

the     propeller            harmonics                 will           sample           the     cabin          modes         in    the       same
manner.           However             the        exterior              fields            will       be     different              from          run
to    run     thus         from        a    spatial             coupling               standpoint,                  the     sampling             of
interior           modes         will          not        be    the        same.            Nevertheless,                   there          is    a

certain        consistency                     in     the       data,            i.e.,       between            the       differences
in    head        (ear)      levels              and       the        differences                  in    head        and       space

average        levels             for       the       two       subvolumes.                     For      instance_               the       third
harmonics            show         the       largest              differences.                      On     the       average           there
are     similar            magnitudes                 of       differences                   for     all       of    the       harmonics

except        for      the       fourth              (and       possibly               the      second).              There           is    mot
mu_h     scatter            except             in     the        case           of    the     fourth           harmonics.


A     standard         hypothesis                    test        is       performed             on      the     data        on     a bar-

monic-by-harmonic                          basis.              Let     _         be    the        true        mean     difference
                                                                           if



(mean        over      Runs           R    and       N)    of        the        difference               of    the     means          in     Sub-

volumes           I and          2,       i.e.,        for       harmonic              H:
                                                                 RN

                                           =                                    mr-    <Snr>N+R                       '
                                                                 r    n

where


                                  '"o::                                   -
 and     n is       one      from          a large             sample             of    runs        (of       total        number           N)

 where       _H     are      the          available              measures               of    average               sound        pressure
 levels       in       Subvolume                2,     and       r is            similarly              from        a large           sample

 R    where       s_       are    the          available               measures              of     average           sound           pressure
 levels        in      Subvolume                 2.        The       hypothesis               is        that    N_        is     zero,          i.e.,




                                                                       -131-
        Table     17.   Differences           Between     Average   Sound       Levels
                        in    Forward     and    Middle     Subvolumes




                                                                                     i

          Run     2          Run 8
    I           0.9             1.1                                       1.0

    2           4.1             4.5                                       4.3

    3       13.6               16.2                                      14.9

    4       13.2                3.2                                       8.2
    5           5.4             6.3                                       5.9




                                                                       H   H
                                                                    <_ I"S2>I0,          1 1,&12
    H     R_n     I0    Run     11      Run     12
m



    I           1.6           4.3         3.0                             3.0

    2       11.3              9.2         6.1                             8.9
    3       13.7             15.0        15.3                            14.7

                8.0           3.2         8.5                             6.6
    4
    5           4.3           7.7         7.5                             6.5




                                                -132-
                                                                                         ORIGINAL PAGE t$
The    estimator          for     _     is                                               OF POOR QUALITY



                                               n        8 r=10, 11&120nrl



                                                                                                 +0 H
                            =(1/6)(0H,10            +OH2,11+OH,12+O_,lO+O_                 11,      8,1    2)

with       sample    standard           deviation



                                                                            _0Hr-3H)       -2 13
                                               =    8    r=10, 1 I&12
The    acceptance          region         for      the    hypothesis         at    the     a    level      of

significance          is     given       by




where  ts;a/2         is the Student   t-distribution  with                                n=5     degrees
of freedom.           The results   are given in Table   18.


                     Table        18.         Results      of    Hypothesis         Tests




Hypothesis               Sample
 Test   for           Statistic           s                Level
                                                            of               Acceptance
 Harmonic
                                                                                R_gion              Accept?


       I             -1.96            1.21                 0.2                     0.73                   no
       2             -4.57            2.35                 0.2                     1.42                   no

       3              0.23            1.61                 0.2                     0.97                   yes
       4              1.63            6.07                 0.2                     3.65                   yes
       5             -0.65            I.78                 0.2                     I .07                  yes




Bias       is   indicated         for    harmonics           I and     2,    where        the    hypothesis       is
rejected.           For     the       higher       harmonics       there      is    no     proven         bias.




                                                         -133-
    -I   I+ _    -2   2
Let _6=_ _ and NS=N_+ 4.5.                     A new hypothesis                 test      (for        the        first
two harmonics)of   the form




does not    indicate       bias.


The space-average          interior            levels         are    calculated           using           the
following    interpretation               of    the      results          above     and other               assump-
tions- â€¢                                                                                              \




       I)   Implications           are     that         on    the    average,           for    Runs         10,       11,
            and     12:




                                                     s4_,4
                                                        2-_2


                                                     sS_,5
                                                        2-_2
                       s3_ ,3
                        2-"2


       2)   The    relationships               assumed          above      between        the     average
            head     (ear)       levels        and      space-average              levels        in        Sub-
            volume        2 are     reasonable               for    use    in     Subvolume               I as

            well,      i.e._



                       sl
                        :.I
                                                      s4_Â°4
                                                        I-_I


                                                      s5-,,5
                                                        I-"I




       3)   The     space-average              levels          in   the    cabin        (for     Runs           10,
            11,     and    12)     can    be     estimated           using        the    swept            micro-

            phone      data      taken     in     Subvolumes              2 and     3    and     the




                                                  -134-
                  average        head        (ear)        level          data     from         Subvolume          I cor-
                  rected        for     bias        according             to    2)     above.


Note     that       the     sample       standard              deviation             in    Table          18 lies       in
the narrow             range between 1.2 and 2.4 dB for four of the                                                    five
harmonics,             but it is about 6 dB for the fourth  harmonic.

Although          no    bias     adjustment               is       warranted           for      that       harmonic,
there        is   a high        probability               (I       chance       out       of    3)    that       the
predicted           space       average         in    Subvolume                 I will         be    off    by    more
than     6    dB,      even     if     all     of    the       assumptions                above       are    accurate.


The     space-average                 levels        are     computed             from      the       measurement
                                                                                        H is         the    space
data with    the            following           relations,  where                      sj
average   sound             pressure           level in Subvolume                       j:


                                             _j=1oS_/10                   ,

                                                                   N

                                             _=(I/N)           _        _j      ; N=3          subvolumes

                                                            J=1

                                                                    N

                                             SH-I(I/m)             _      (x_j-_H)2          I_
                                                                                              re=N- I
                                                               J=1



Swace-Averaze              Level        (Harmonic              H)



                                         S_H=1OlÂ°g

(I-=)    _    Confidence             Limits         (on the             s_ace     average)



                    SPL_-a=      I010 g(_+           sHtN_ i ;a/2/_-N)                     â€¢


The     calculated             space-averages                  and       the     95%      and       99%    confidence
limits        are      given     in     Table        19.




                                                            -135-
      Table             19.       Measured          Space        Averages        and     Confidence           Limits




Run        No.     10



H          _           Bi as
                   Correction                s_             s_            s_     __ H
                                                                                 SPL              SPL_    5 *            SPL 99


I      103.6              -2            101.6           102.0        99.5        101.2       96.1-103.5                  <105.3

2      101.5              -4.5           97.0            90.2        82.0         93.2            <99.3                  <102.3

3          94.5               0          94.5            80.8        78.8         90.0            <96.9                  <100.0

4          81.2               0          81.2            73.2        68.1         77,2            <83.5                   <86.4

5          75.0               0          75.2            _.7         67.3         72.2            <77.2                   <80.0



Run        No.     11

                          Bias
H      MH          Correction                SlH            sH            s_     _H               SPL95                  SPL 99


I      101.9              -2             99.9           97.6         97.7         98.5       91.7-10          1.1        <103.    I

2          98.0           -4.5           93.5            88.8            79.5     90.1            <95.8                   <98.6

3          94.2               0          94.2            79.2            75.1     89.6            <96.6                   <99.8

4          74.9               0          74.9            71.7        64.5         72.1            <77.    I               <79.9

5          75.5               0          75.5            67.8        64.0         71.7            <77.8                   <80.7



Run        No.     12

                          Bias
                                                                                                                         SPL 99


I          96.8           -2             94.8            93.8            96.2     95.0       89.8-97          .3          <99.2

2          93.1           -4.5           88.6            87.0            76.1     86.3            <91.5                   <94.4

3          90.5               0          90.5            75.2        67.9         85.9            <92.9                   <96.0

4          75.5               0          75.5            67.0        60.5         71.4            <77.9                   <80.9

5          70.7               0          70.7            63.0        60.0         66.9            <72.9                   <75.9




* Only         the       upper      limit          is   defined           for   those     cases       with         the    "less

    than         (<)"     symbol




                                                                 -136-
5.3            Com_uter           Simulation               of    Flight          Tests


As     discussed                in     Section          4,      the    exterior              field       predictions                made
with           the       ANOPP       program           need      to    be       examined           to     determine             whether

the        PAIN          grid     is      properly           located            and     also       to    see       if    the       pres-
sure           field        decreases            sufficiently                   over       the     length          of    the       grid.
For        the       present           aircraft,             a preliminary                   selection             of    the       grid
centering                 variable             (i.e.,        centering               relative           to    the       maximum

predicted                 sound        pressure            level       on       the     exterior             of    the       fuselage)
is     k       =8.        Figure          36    illustrates                the       selection.
           P


                    ANOPP       Prediction              Methodology


The        ANOPP          program          cam       predict          propeller              tones       using          various
methods              and       the     degree         of     complexity               of     the      calculations                 will
impact              the     user.          Two       methods          of    concern             that     cam       be    used       to

predict              the       free       field       propeller             noise          in-flight              are    the       so-
called              Method        I or         full     Blade         formulation                in     which          only    40    of
the        pressure             siguatures              (out      of       160       required)           cam       be    computed
at     amy          one     time,         and    the       Method          3 or       compact           chord          approximation
(line              source       model)          in    which        all      160       signatures              cam       be    computed
simultameously.


Run        No.       2 was        selected             for      comparing             the       full     blade          and    compact
chord              models,        with         the    hope       being          to    use       the     simpler          Method          3
on     the          three        flight         comparison             runs          10,     11,      amd     12.        Figures             45
and        46       illustrate             the       differences             in       the       results           of    the    calcula-

tions.               Figure          45    gives        the      sound          pressure           levels          predicted             along
the        line       2=I        (Figure         3)     that      were          computed           using          both       methods
(the        Method             I or       full       blade       prediction                is    considered              the       most

accurate                 prediction             possible).                 It    is     seem       that       the       amplitudes
forward              of     and      also       near       to    the       propeller             plane        compare          quite
well           for       all    harmonics.                 The     full         blade        predictions                exceed       the
lime           source          predictions              aft      of    the       propeller              plane,          usually          by
2    to        5    dB    after        each      has       rolled          off       about       10     dB    below          the    peak



                                                                  -137-
                                                                   ORIGINAL PAGE |4
                                                                   OF POOR QUALITY

                                          AXIAL INDEX, k

      1   2   3      4     5         6      7     8     9     10   11   12   13   14    15   16
      I   I   i      I     I         l      I     !     m     I     I   $    I    i      i   j
140



135



130




                  FIGURE       45.       AMPLITUDE     COMPARISON,    FULL    BLADE    VS.
                                         COMPACT      CHORD   FORMULATIONS


                                                      -138-
              OF POOR          q J_,k.I'_t'




                                                        Z
                                                        Â©
                                                        V_
                                                        m



                                                        ,<
                                                        =

                                                        IJ.J
                                                        V'I
                                                        ,<
                                                        "r"




                                                        LI.I

                                                        D
                                                        k;
                                                        LL




I   I               I                _        _'_
                                         I      I   I



        (sa,_6ep)       Hi} 'os_qd




           -139-
levels.            Certainly            in      the       case       examined            most        of    the       acoustic
energy        incident           on     the         fuselage           is    within         the       grid       area.            The
levels        of the           first       harmonic              decrease           more        than       12 dB        from

k=7     to    the       extremes           of       the       grid     and      much      larger           roll-offs              are
predicted           for        the    higher             harmonics.               The     ANOPP           predicted              roll-
off    of     the       over-all           sound          level        is    quite        consistent                 with        the
empirical           prediction               made         using        Figure        39     as       discussed              in
Section           4. I.


Figure        46    shows        the       phase          calculations                 (_=I)         for       the    various
harmonics           as     predicted                by    ANOPP        using        the     two       methods.               There
appears           to be        very     little            similarity.                But        the       PAIN       program
is    concerned            not       with       phase          point-by-point                   on    the       grid,        but
with     phase          difference              point-to-point.                      Phase           differences                 can
be    compared            by    adjusting                the     phase       predictions                  to    their        re-
spective           means        and     then         by       overlaying            them        as    done       in     Figure
47,    where        it     is    observed                that       the     phase        information                 compares
quite        well.         On    the       basis          of     these       comparisons,                  it    was        decided
that     the       ANOPP        Method          3    was       sufficiently               accurate.                  Later        to
verify        the       correctness                 of    this       decision,            the        Run       2 propeller
noise        predictions               (both         methods)             were      used        as    an       input        to    the
PAIN     program           and       the     interior               levels         predicted              in    the     Merlin
IVC     aircraft           were        compared.                 This       was     done        for       blade        downsweep
only.         The       differences                 in    predicted             interior             levels          were        such
that     the       full        blade       model          resulted           in     very        slightly             higher        in-
terior        levels.            The       results             for     the      first       harmonics                differed

by     1.05       dB;     for    the       second:              1.46      dB;      the     third:          0.05        dB;       the
fourth:           2.04     dB;       the     fifth:             1.84      dB.


5.3.2         Predicted              Exterior             Levels


Tables        20,       21,     and     22      give          the    ANOPP         predicted              free       field
flight        levels           along       the       grid        line       _=I.         The     data          are     also
given        in    Figures           48-53.              It    should        be     recalledthat                     the     free
field        amplitudes              are     increased               according             to    Eq.       (43)        of    Ref-


                                                                 -140-
    OF POOR   QUA_.,I_




W


m



N




                             _,_
                         I     I   I




              H__Hj




          -141-
           Table     20.         Exterior          Levels            in        Flight         Run     No.     10

                                 (ANOPP          Compact            Chord,             free     field,_           =I)

                     Sound         Pressure            Level,             dB     re     20     ,Pa
Harmonic

    H        k=1             2              3                 4                  5              6             7             8

    I       122.4          125.4       128.4                131.4          134.1              136.1         136.3        133.5

    2       107.4          112.3       117.3                122.3          127.1              131.2         133.0        129.2

    3        92.2           98.8       105.7                112.7          119.6              125.8         129.3        125.3

    4        77.0           85.2          93.9              102.9          112.0              120.2         125.5        121.7

    5        61.7           71.7          82.1               93.0          104.1              114.5         121.6        118.4
                      i                            i   i             l




                                   Phase,         _H        (degrees)

    I       -91.7     -102.1          -111.9           -120.9             -129.0         -135.1        -134.3           -103.7

    2       "52.3          -72.6       -91.2           -108.2             -124.9         -137.7        -146.7           -132.2

    3       -11.7          -42.2       -69.3                -94.5         -117.3         -138.3        -155.7           -156.4

    4         29.9         -11.0       -47.2                -79.7         -109.5         -137.4        -162.7           -177.4

    5         71.9          20.9       -24.0                -64.1         -101.0         -135.6        -168.3            164.2

                     Sound         Pressure            Level,             dB     re     20     ,Pa
Harmonic

    E        k=9            10              11               12                 13             14            15            16


    I        133.4         132.3          130.0             127.4              124.7          122.1         119.5        117.0

    2        125.9         122.9          118.7             114.1              109.6          105.2         101.1          97.2

    3        118.2         113.2          106.9             100.5               94.3           88.6          83.1          77.8

    4        110.4         102.9            94.7             86.5               79.0           71.9          65.2          58.6

    5        102.8          91.3            81.3             71.8               63.3           55.3          47.4          39.5


                                   Phase,         _H        (degrees)

     I      -70.7          -67.0       -70.4                -75.6          -80.9              -85.8         -90.0        -93.2

    2        -97.2         -96.1      -105.9               -I 17.8        -129.2          -138.0        -146.4          -151.3

    3      -123.8         -123.7      -140.0               -159.6         -177.9              167.5         157.2         151.3

    4      -154.2         -151.3      -174.1                157.7              132.1          112.9         100.5          94.1

    5        167.0         178.4          150.5             112.3               79.3           56.5          43.0          37.5




                                                           -142-
                                                           ORIGINAL    PAC_E 19
                                                           OF POOR    QUALITY




                                            AXIAL     INDEX,   k

               1   2   3   4    5   6             7    8       9      10   11     12   13    14      15   16

               I   I   I   I    I       I         I    I       I      1    I      i     I        I   I     I

         140

               F
         135



         130



         125

 tll
a_

 =,      120
Â¢,l,,I


  L

t=       115


--.1
ELI
         110
ELI
....l

ELI

==
         105

 el-

 l=
 II
         100
lit




          95




          85



          80



          75



          7O



                               FIGURE       4_.       EXTERIOR    LEVELS  (FREE        FIELD),
                                                      FLIGHT   RUN NO. 10
                                                       -143-
                    ORIGINAL     PAGE I_
                    OF POOR      QUALITY




           II                    I!       II            II   II




                                                                               T"




                                                                               Z
                                                                               Z




                                                                               _3
                                                                               m


                                                                               Iv


                                                                               .J
                                                                               LU
                                                                               m
                                                                               LL
                                                                               LU
ELi                                                                            I'1
==
                                                                                U.
._=
I=                                                                              uJ
C                                                                               <
                                                                                "I-
                                                                                Q.




                                                                                UJ


                                                                                L3
                                                                                i
                                                                                I1




                                                                      q.




      Â¢=


                l    I                I             I             I        I




                     ( sa,_z6ap)Xil       ' aseqd




                                  -144-
           Table     21.        Exterior        Levels        in    Flight        Run    No.    11
                                (ANOPP        Compact        Chord,        free    field,      _ =I)

                     Soured Pressure               Level,      dB     re    20    _Pa
Harmonic
   H         k=1            2             3             4             5            6            7          8

    I       12i .0     124.0         127.0           129.9         132.6         134.6      134.7       131.5
    2       105.9      110.8         115.8           120.8         125.6         129.6      131.4       127.4
   3         90.5          97.1      104.0           111.1         118.1         124.2      127.7       123.7
   4         75.1          83.4          92.1        101.2         110.3         118.6      123.9       120.3
    5        59.7          69.6          80.1         91.2         102.4         112.8      119.9       117.1

                                 Phase,        _     (degrees)

    I      -100.7     -110.1       -I 18.8          -126.9     -134.0        -139.3       -138.2       -107.4
    2       -67.8      -85.9       -102.4           -I 17.5    -131.3        -143.5       -151.4       -137.8
   3        -33.8      -60.8         -85.0          -106.9     -127.0        -145.5       -161.0       -162.8
   4           1.3     -34.9         -66.8           -95.3     -121.5        -146.1       -168.6        176.3
   5         36.8          -8.1      -47.7           -82.9     -I 15.2       -145.7       -174.9        158.3

Harmonic             Soured      Pressure           Level,     dB     re    20    _Pa

   H         k=9           10            11            12           13            14           15         16

    I       131.3      130.4         128.2           125.6         122.9         120.2      117.6       115.6
    2       123.5      120.6         116.4           111.8         107.3         102.9         98.8      94.9
    3       115.4      110.3         104. I           97.6          91.5          85.7         80.3      75.1
    4       107.4          99.0          90.9         82.7          75.3          68.4         61.9      55.4
    5       IOO.8          85.3          75.4         66.3          58.6          51.1         43.6      36.0


                                 Phase,        _     (degrees)
    I       -70.1      -64.5         -67.1           -71.6         -76.5         -81.o      -84.9       -87.9
    2       -97.7      -92.7       -100.6           -111.4     -122.1        -131.4       -138.5       -143.2
    3      -127.0     -I 19.5      -132.8           -150.9     -168.4            177.2      167.3       161.8
    4      -163.8     -148.0       -165.5            167.8         142.4         123.4      111.6       1o6.2
    5       148.7      172.4         156.4           118.8          86.2          65.2         53.9      50.4




                                                   -145-
                                         AXIAL INDEX,k

            1     2   3   4   5    6     7       8      9   10     11    12      13      14      15   16

             I-   I   I   I   I    I     I       I      I   I       I    i        I          i   I    t


      140



      135
            F                                                    ORIGINAL.
                                                                 OF POOR
                                                                              PAGE
                                                                              .QUALITY
                                                                                        _S




      13o



      z2s
                                                                                         H=I

      120



      115
eL




      110

eel


      105



      100

Z


C_     95
Z




       9O



       85



       80



       75



        70



                          FIGURE   50.       EXTERIOR    LEVELS  (FREE        FIELD),
                                             FLIGHT   RUN NO. 11




                                                -146-
                     II     II                II   I|




                                                                    _=-
                                                                    p-




                                                                    Z
                                                                    Z
    Z


    m                                                               "r"
                                                                    i
                                                                    i
    wm                                                              ii




               i
                                                                    C:
    tmo                                                             ..J
                                                                    L.U
                                                                    i
                                                                    u.
                                                                    Ill
I
N
                                                                    LL
N


    m
                                                                    <
                                                                    "T"
                                                                    O.


              II


                                                                    LU



    qP                                                              LL

    eq




    N




    wm




          I                      I       mi             _
                                          I                 l   I




                   (saa,_6ap) XB asoqd




                          -147-
           Table    22.         Exterior          Levels            in    Flight          Run    No.     12

                                (ANOPP          Compact            Chord,         free     field,       I =I)

                    Sound        Pressure              Level,        dB     re     20     _Pa
Harmonic

    H        k= I           2              3                  4             5              6             7          8

    I       118.2      121.1          124.        i        126.9         129.5           131.3         131.3     127.3

    2       102.7      107.6          112.6                117.6         122.3           126.3         128.1     123.8

    3        87.0          93.6       100.6                107.7         114.6           120.8         124.4     120.8

    4        71.1          79.5           88.4              97.6         106.7           115.0         120.5     118.0

    5        55.2          65.3      76.1             _     87.4          98.7           109,2         116.6     115.1


                                  Phase,          _H(degrees)

    I      -120.7    -127.8         -134.3             -140.2        -145.4         -148.9        -147.2        -118.5

    2      -101.3    -114.9         -127.1             -138.2        -148.2         -156.9        -162.6        -153.6

    3       -80.8    -100.9         -118.6             -134.5        -148.9         -162.2        -173.8        -178.9

    4       -59.2     -86.0         -109.1             -129.5        -148.3         -165.9             177.3     161.6

    5       -36.7     -70.3           -98.9            -123.8        -146.8         -168.6             169.8     145.6

                    Sound         Pressure             Level,        dB     re     20     _Pa
Harmonic

    H        k=9           10              11                12            13             14            15         16

    I       126.5         126.0       124.1                121.6         118.9           116.2         113.6     111.1

    2       117.4         114.8       110.9                106.3         101.8            97.4          93.4      89.5

    3       109.1         102.1           96.2              89.8          83.8            78.3          73.2      68.4

    4       104.4          87.8           77.1              70.3          64.9            59.5          53.8       48.0

    5       102.0          86.1           72.6              61.6          52.4            44.3          36.7       29.2


                                  Phase           SH       (degrees)

    I       -70.5      -60.3          -60.6                -63.7         -67.4           -71.0         -74.2     -76.7

    2      -105.6      -88.0          -90.9                -98.9     -108.0         -I 16.3       -122.7        -126.7

    3      -153.4    -120.8          -123.2               -137.5     -153.9         -167.6        -176.4          179.8

    4       152.6         164.4       174.7                156.8          137.3          125.5         120.4      120.8

    5       114.9          78.4            50.9             41.7           42.8           46.4          51.5       59.3




                                                      -148-
                                                                                            ~-   i,_.
                                                                         ORIGINAL       'PAC,_-....
                                                                         OF pOOR        Q Up':_''T{
                                              AXIAL INDEX, k
          1    Z   3     4      5         6      7     8       9    10     U     12        13           14         15   16
          I    i   I     I      I         l       l     J       i   l      l        l       l           I          I    J


    140   mm




!

    135 -



    130




    120

                                                                                                             H=I




     95




     85
                                                                                                 H=3


     8O



     75



     70




                       FIGURE       52.        EXTERIOR   LEVELS  (FREE         FIELD),
                                               FLIGHT   RUN NO. 12



                                                            -149-
                               ORIGINAL     PACE        ___,,,
                               OF POOR     QUAL;'_+_,"




                                                                  d
                                                                  Z
       ,rap                                                       Z

                                                                  e,,
       m



                                                                  !
       o,i

                                                                  LL.

                  D
       m


                                                                  m
                  m                                               U.
.=.=
                                                                  L_
,.1'
 C
l,m&   _'=        n



                                                                      _J
       =O
                                                                      <

                                                                      0.



                                             II


                                                                      L_


                                                                      L3
           ,rap




                          u_




                                $I
                      !                           I



                                     (saa_fap)        Hi_ aseqd




                                          -_5o-
erence        I to       account             for       the       blocking           by     the       fuselage         surface.

For     consistency                with          the       scale       model        test        results,           a maximum
increase           of    4 dB          is    allowed,                i.e.,        the     right       hand        side     of
Eq.     (43)       is    multiplied                   by    a    factor           0.8.


The     scale-model                tests          showed             that     the       reflection            effects           dissi-

pate     faster          than          the       PAIN       model          predicts,            so    the     computer           gen-
erated        field       may          be    "stronger"                than        the     actual          field.          No

changes         are      proposed                in    propeller              data        input,        however,           until
ANOPP     calculated                   blocked             pressures              are     available.


5.3.3         Fuselage             and       Cabin          Modeling


The     fuselage          modeling                is       exactly           as    detailed           in     Section        4.2.2.
The     structural                modal          file       (identical              to     that       in     Appendix           C)       is

created        using          the       input          data          specified            for     the      business         aircraft
as    given        in    Table          13.


The     cabin       modeling                is    also          basically           identical.                The        floor
angle     is       taken          as    50 Â° .         The       acoustic           modal         file       such     as    shown

in    Appendix           C    (that          output             by    PAIN)        is     created          once     the     cabin
length        is    specified.                    Results             given        in     Appendix           C were       for        a

cabin     length             of    7.75          m.        In    the       present         case,        the       length        is
7.89     mÂ°        Also       the       trim          panel          surface        mass        is    different            (1.95
kg/m 2    as       noted          in    Section             5.1).



Both     of     the      input          files           (to      PAIN)        are        complete,           or    sufficiently
complete           to    allow          use       of       the       low     frequency            calculation              proce-
dure     for       all       5 harmonics.


5.3.4         .PAIN      Input          and       Output             Data


Input     data          for       the       PAIN       program             consist          of       the     output        files
from     MRPMOD          and       CYL2D          plus          its    own        exclusive           data.         These        data

are     the     same         type       as       was       used       for     PAIN        input       in     the    scale        model


                                                                     -151-
tests.           Table        6 should              be    consulted               to    review         the        requirements.



Damming


The    structural                 loss        factors        of       the     bare       (or     untrimmed)                   fuselage

are taken  as 2/ fr where   fr is the resonance    frequency.                                                                  PAIN
will calculate  trimmed   fuselage   "loss factors"    necessary                                                                 for

                                                                              _r,       and Ur', "
the    transmission                    predictions,               i.e.,


The    acoustic              loss        factors          are     input           as    zero      so     that          PAIN        will
calculate              the    sidewall              conductance               and       then      the     loss          factors.



The trim             panel   loss  factor                  WT is set to 2.0                       to force              PAIN   to
calculate              (what  is believed                    to be) the most                      accurate              trans-

mission           coefficient.                  Figure           54    shows           the    effects             of    changing

WT"        The       predicted            interior           levels           will       not      be     affected              nearly
as    much        as    these          curves        might        imply           because         a resonance                  con-
trolled           trim       will        also       more     readily              absorb        sound         from        the

cabin       space.            For        instance           in    Run        10,       reducing          WT       from        2.0    to
0.2    increases              the        predicted           space           average          level       by       only        2.75
dB    for       the     first          harmonic            (104.5          Hz).         It     actually            decreases
it    by    0.48        dB    for        th_    second           harmonic              (209.1       Hz)       and       increases
it    by    only         1.95       dB    for       the     third          harmonic            (313.6         Hz).            An    in-
crease          of     4.58       dB     is    predicted              for     the       fourth         harmonic               (418.1
Hz)     and       3.73       dB     for       the     fifth       harmonic              (522.7         Hz).            The     above
differences               (quoted             for    blade        downsweep)                 show      that        the        trim

effects           are     not       simply          describable               in       terms      of     a    transmission
coefficient               (or       transmission                 loss),           but     onl 7     within             the     con-
text       of     the     PAIN         analytical            model.               Until        future         superior
developments                 replace           the       present            trim       model,       it       is    recommended

that       _T     be    arbitrarily                 set     at    2    to     create          a trim          model          valid        in
the     frequency             range           from       about        50     to    perhaps          1000          Hz.        Reference
6 may        be      consulted            for       review        of        the    trim        model.




                                                             -152-
                                                 OF P_J,_._:,
                                                           C'.j#,.L_.i";
                                                                   _"
         40



         35



         30

                              IT=I. 95 kgJm2                             " /
         25



         20




_

    _
    =.
         zs

          lo                                         .7/                       "
           5



           0



         -5



         Â°10



         -15



                I   I     I        I     I       I     I     I      !     I    !      I          I
               63   80   100      125   160     200   2.5u   315   400   500   630   800        1000

                                             Frequency, He



                    FIGURE       54.     EFFECT  OF VARYING     LOSS FACTOR,              T/T
                                         ON TRIM FACTOR     rt= IC TM ! z




                                                 -153-
Propeller

The    propeller            is    located             as    before           by    the          variables           rp,        Zp,
and     @ (Figure           36).           As    can       be    seen        in    the          figure        rp    is     2.35        m,

Zp is 1.12 m,               and _ is 75 Â° (recall                           that the PAIN                     input  re-
quirement for               $ is to the nearest                            5Â° increment).                      In the
present        case,        the    number             of    blades           B is       4 and          the     propeller
rotation        speed        N    is       1568       rpm.           The     blade          sweep        variable              is
+I    (downsweep)            or       -I    (upsweep).                 PAIN        must          be    run     twice
since     there        are       two       propellers                rotating           in       the     same       direction
and    the     interior           levels             predicted              for    blade          downsweep               and       up-
sweep     must        be    added          (on       a power          basis)           to       obtain        the       pre-
dicted        levels        in-flight.


Pressurization


The     effects        of    pressurization                      are        accounted              for       (in    PAIN)
through        adjustment              of       the    exterior              and       interior              air     densities
and     sound       speeds.            The       flight          status           is       determined              by     the        ex-
terior        and     cabin        temperatures                  and        the       cabin        pressure.               The
correct        exterior            sound         speed          is    341.6         m/s.           This       is     based           on
on    temperature            of       17Â°C       (Table          15)        which          is    higher           than     the
standard         at    5000        ft.          The    ANOPP           exterior             sound        speed           was
taken     as 334.1           m/s       which          is     nearer          that          of    standard            tempera-
ture.         This     was       an    error          in     the      ANOPP           input,          but     a     difference
of    only      slightly           over         2%    less       than        the       true        sound          speed        is
not     significant.                  The       PAIN       input           duplicates              the       ANOPP        input
of    334.1      m/s       with       an     exterior            density              of    1.1012           kg/m 2.           The
interior         sound        speed         is       343     m/s       with       a    density           of        1.204       kg/m 2.

This     latter        value          is    based          on    an        ICAO       standard           pressure               alti-
tude     (12.243           psia       at     5000       ft plus             a 2.5          psi     differential)                     and
68Â°F     in     the    cabin.              Had       comparisons              been          attempted               at    higher

altitudes,            greater          care          would       have        had       to       have     been        taken           in
duplicating            flight          exterior              conditions.                    However           here        the
errors        incurred           in    predicting                exterior              prop noise                 are     not
considered            to    be     sufficiently                  great         to      force           a re-run           of     ANOPP
for     the     three       runs        10,       11 and         12. '_Estimates                       are    that        much        less


                                                             -154-
than       a one           decibel        change        in     exterior             levels       would         result          if
r e- run     i



Inwut        and       Output        Data


Formatted              input        data     for    Programs             MRP,       MRPMOD            and    PAIN        are
given        in       Appendix        D (Run         10 only).                 Also       give n       in    the        same

Appendix              are    the     propeller            blocked           field         data        output        by    PAIN
(Run       10)        and    the     interior           predictions                 for     that       run.         In    the
interest              of    brevity,         similar           input        and      output           data        for    Runs
11    and        12    are     not     shown.



5.4        Comwarisons               to    Flight         Test        Results


The     fundamental                 flight        test       comparisons                 are    summarized               in
Tables           23    and 24        and     in    Figures            55,      56     and      57.      The        follow-

ing     is       a brief          description             of     the      findings:


           I)         Predictions            for     four        of      the    five        harmonics              fall       with-
                      in    the     99%     confidence              limits          of    the     measurements                  (for
                      all    three        runs      (10,       11 and          12)).



           2)         Predictions            for     4    out       of    5 harmonics                 also        fall    within

                      the    narrower         95%        confidence             limits           for    Run        10,    and       in

                      Runs     11    and     12,     3    out       of    5 predictions                  fall       within          the
                      95%     confidence            limits          and     predictions                for        the    2n_.dd
                                                                                                                              har-
                      monics        fall     outside           by     1.3      and       1.4     dB    respectively.


           3)         In    each     run,     the        prediction             for       the      fourth          harmonic

                      yields        the     major        discrepancy.


                      The     sample        mean     error          between           predicted              (dcwnsweep

                      plus     upsweep)           and     the       measured             space        average           level
                      is    +4,3     dB     across        all       harmonics             and      runs       (15       datum;

                      predictions            exceeding              measurements)                  with       a    standard


                                                               -155-
                         OX           0                                      t_       t_
            |                                                                     @       @                                   @       â€¢

                         0                                                   â€¢--      t_                              0
            0                         v                                      v        V                               v           V



                         _-           OX          OX        U'X    0
                                                                                  â€¢       @        â€¢     â€¢        â€¢           â€¢       @       â€¢       â€¢        â€¢

                         â€¢-           I/X         ,-.       OX     ,--       od       P_.      0       Â¢kl    0       ,'-         _0      ,-"     0       "-
                                                                                                       ,.--       !




                         0            ,-
                                                                                                                              â€¢       @



                         00X

0                                     V                                      V        V


                                                                                                                       0          tch     _       .._"    0",
                                                                                                                              â€¢       @       â€¢       â€¢        â€¢




                              â€¢               â€¢        @     â€¢          â€¢                                                     â€¢       â€¢       @       â€¢        â€¢

                     0                                                        0       _-       0       U'_ _-
                         0             O'x        Ox        aO     _          0       O_       Ox      _0  _-

          q=l




      0                                                                       Ox      O'x aO           cO     _0




                         Ox           _.0         _.-       OX     0
                              â€¢               â€¢         @    â€¢           â€¢        â€¢        â€¢       â€¢      Q       â€¢
o
                         Ox               OX aO             cO     O_-

                     0
      0




t_                            â€¢               â€¢         â€¢    â€¢         .0



                         0                0       ,-        ,-"    _1                                                     0       0       ,--     ,--     Â¢kl
 0
f-I



                o


                0




                                  .                                                                                       t_J
                _0




                                                                  -I 56-
               Table     24.     Sample      Statistics          and   Acceptance        Regions

                                 for   Interior      Sound        Levels    (Table       23)




 Hypothesis                       Sample              Level                Ac c eptanc    e
     Test                      Statistics                of                   Region           Accept?
         on
                               _(dB)      s(dB)    Significance               (+dB)



All     15     datum
                                                                                                   no
(3    runs      x    5         4.28        4.12           0.2                  1.43
                                                                                                   no
harmonic        s)                                        0.05                 2.28
          \


                                                                                                   no
12     datum                   2.62         2.43          0.2                  0.96
(H=4     excluded)                                        0.05                  1.54               no


                                                                                                   no
Run     #10                    4.00        3.62           0.2                  2.48
(5    harmonics)                                          0.05                 4.49                yes

                                                                                                   no
Run #11                        4.56         5.42          0.2                  3.71
(5 harmonics)                                             0.05                 6.72                yes

                                                                                                   no
Run #12                        4.28         4.08          0.2                  2.80
(5 harmonics)                                             0.05                 5.07                yes

                                                                                                   no
H=I                             1.83        0.51          0.2                  0.56
(10,      11    and      12)                              0.05                  1.26               no


                                                                                                   no
E=2                             6.5         o.56          o.2                  o.61
(10,      11    and      12)                              0.05                  1.39               no


                                                                                                   no
H=3                             1.33        0.60          0.2                  0.65
(10,      11    and      12)                              0.05                  1.49               yes

                                                                                                   no
H=4                            10.93        1.76          0.2                   1.92
(10,      11    and      12)                              0.05                 4.37                no


H=5                             0.80        0.92          0.2                   1.00               yes
(10,      11    and      12)                              0.05                  2.28               yes




                                                     -15V-
                                 ORIGINAL PAGE 1_
                                 OF POOR QUALITY




      110   -
                                                                                       Run No.   10
                                                                                  â€¢    SaJmle Mean
                  H=I                                                             â€¢    PAIN Prediction
      105   -



      100   -



MI
                                                             \
       95   -



       90   --




t_
       85   --
L_
--J                                                                           \
L_
Â¢Â¢
       80   --
V1
V1
L_
Â¢Â¢
eL


IÂ¢     75   --

V1



       70   -


                                            95% Confidence  that   true      mean lies
       65                                       below these levels


                         _--_               99% Confidence       that true   mean lies
       6O                                       below    these    levels



       55



       50   n




            0      100                200          300                 400            500         600    700


                                                 Frequency,       He
                 FIGURE         55.     SPACE-AVERAGE    SOUND LEVELS INSIDE
                                        AIRCRAFT   _ 238 KIAS (ALTITUDE=5000ft)


                                                     -158-
                                              ORIGINAl._,_,:,
                                                          _
                                              OF POOR Q:J,-4_._'
                                                          _'"




      110
                                                                                Run No. 11
                                                                           â€¢    Sample Mean
      105                                                                  1    PAIN Prediction
                   H=I



      100                             2



      95
                                                    \\

eL    9O
=L




       85


.i
LU     8O
LU
--a

LIJ

       75   n
gn
L_J




W      70



       65
                                          95% Confidence that true       mean
                                          lies below these levels

       6O

                                          99% Confidence that true      mean
                                          lies below these levels
       55



       5O   lid



            I         I           !            I               I            !             I        I
            0        100         200         300              400         500            600      700

                                            Frequency, i_.
                  FIGURE   36.    SPACE-AVERAGE              SOUND     LEVELS     INSIDE
                                 AIRCRAFT          _     216 K1AS   (ALT1TUDE=S000ft.)
                                                   -1 9-
                                          ORIGINAL PAGIElg
     110                                  OF POOR QUALITY
                                                                                                            Run No.   12
                                                                                              â€¢             Sample _an
     105                                                                                       m            PAIN Prediction


                        H=I
     100
                        \
                                                           3                                            \

      95



 q    9O


O

      85       in




.3    80

L_
,W                                                                                                  5
L_
      75
V_
L_



      7O

V_


      65


                                              95% Confidence that true
      60                                          lean lies below these levels


                                              99% Confidence            that      true
      55
                                                     Ran       lies    below      these    levels



      5O       /



           t                I

           O                100         200          300                    400              500                  600         70O


                                                   Frequency,         H_.
                    FIGURE        57.   SPACE-AVERAGE                  SOUND             LEVELS             INSIDE
                                        AIRCRAFT       @ 165KIAS               (ALT1TUDE=5OOOft)



                                                       -_6o-
                  deviation                  of    4.1        dB    (Table           24).



         5)       Excluding                  the     results             for        the     fourth           harmonic                 (i.e.,

                 using             12    datum),              the       mean        error        is        2.6        dB    with         a
                   standard              deviation                 of     2.4       dB.



         6)       In        both        cases        4)       and       5)     above,        a     standard                 hypothesis
                   test        clearly              (but       not       surprisingly)                      shows           a     bias

                  present               in    predictions.



         7)       Examined               run-by-run,                    the     sample           mean        errors               ranged

                  between               4.0       and     4.6       dB       and      the    sample               standard               devia-

                   tions           between           3.6        and      5.4        dB.      At        a    sufficiently                      low
                  level            of    significance,                       none      of    the           three           runs       can         be

                   shown           to    be       biased,           but        actually            this          is        due     to        the

                   large           discrepancies                    between            the       predictions                      and        meas-
                  urements               for        the       fourth           harmonics.



         8)       Examined               harmonic-by-harmonic,                               the           sample           mean         errors

                   ranged           between              0.8       and       6.5      dB,    but           ballooned               to        10.9        dB
                   for       harmonic               4.        In    all        except        the           case        of       the      third

                   harmonics                 bias        is     present.               Of    great           significance                         how-

                   ever       is        the       low      level          of    random            error           as       exhibited                by
                   a    standard              deviation                 of     less        than        I dB           for       four         of

                   five        harmonics                 and       only        1.8     dB    for           the        fourth          harmonic.



It    should           be    noted           that        bias       adjustments                   were       previously                      made        to

the     raw      data        to     obtain           estimates                 for     the        space           average             levels             in

the     forward             subvolume.                   Had       those        adjustments                  not           been       made,            i.e.,
if    the     head          level        measurements                     had       been     taken               as    representative

random        samples              and       the     average              level        taken           as    the           space         average
in    the     forward              subvolume               for      the        first        two        harmonics,                  the        errors

would       have        been        smaller              (see       the        numbers            in       the        parentheses                   in

Table       23     and       also        refer           to     Figure          58).         The           sample           mean         error

between          predictions                  and        measurements                  across              all        15    datum            would



                                                                    -161-
                                                  ORI_NIkE        PAC_Z t_
                                                  OF POOR         QUA Ll'i_q




        Ii0   --

                                                                      PREDICTIONS
                                                                                     RUN
        105   --

                                                                             â€¢       10
                                                                             â€¢       11
        100
                                                                             â€¢       12
                          \

        95    -
eL
                              \

         90   -


m_

        85    -
J
uJ




ELi      80   -
_e

I#'_"
_q
ELi

        75

|
         70   -



                         NEASIJRENENTS
         65   -
                                      U


         60   --                  0   10
                                  O ii
                                      12
         55   -



         50   -

              !     !                    I        I               I              I          I     !
              0    100                200        300            400          500           600   7O0

                                                Frequency,     H,_-
                   FIGURE             58.    COMPARISON    OF PREDICTIONS    AND
                                              MEASUREMENT5      WITHOUT  ASSU MED
                                              BIAS CORRECTIONS.

                                                       -162-
be        reduced             to    3.4     dB    with          a    standard           deviation              of      4.1     dB.        By
excluding                 the       fourth        harmonics                these        become           1.5      dB     and     1.1       dB

respectively.                         As    before          bias          is    indicated.               Now        however           the
mean        errors              (averaged             across             the    three        runs)        for       the       Ist     and
2nd        harmonics                are     only       0.9          and    3.0    dB     respectively                    with       stand-
ard        deviations                 of    0.35       dB       and       0.85    dB.         _Fhat these                mean       to    the
eventual                 user       of     the    PAiN          program          is     a matter             to     be    discussed
in        the       concluding              section.

      \

Next        consider                the     accuracy                of    the    predictions                 made        with       the
"high           frequency                formulation".                     As previously                  stated,             these
calculations                       are     always          output          by PAIN.               Thus       there        are       com-
paritive                 predictions              for       all          harmonics           where        results             from       the

low        frequency                technique              are       available.               At     sufficiently                   low
frequencies                    predictions                 made          with    the     high        frequency                procedure
may        be       spurious             and     if    so,          they       should        be    ignored.               Use       of    the
low        frequency                procedure              is       preferred           whenever             possible.               Eow-
ever,           as       noted        in    Section             4.0,       for    large           fuselages,              the       high
frequency                 procedure              will       have          tobe        used        above        the       first        few
harmonics.      â€¢   Â°




The        results              for      the     present             flight       tests           are     shown          in    Table        25.
Predictions                     for      the     first          harmonics             are     spurious              and       are     dis-
carded.                  The       mean     error          for       the       twelve        remaining              datum       (2nd
through                 5th    harmonics)              is       -1.43          dB with        a fairly              large       standard

deviation                 of       6.26     dB.        At       the a=O.05              and       0.2     levels          of    signi-
ficance,                 a zero          bias     hypothesis                   test     yields          acceptance              regions
of        -+3.97         and       -+2.46      dB.         Since          the    mean        error        falls          within          ei-

ther        of          these       bounds,           the       hypothesis              is    accepted.


Reviewing                 the       results,           it       can       be    seen     that        the low             frequency
formulation                    tends        to    over-predict,                   while           the     high         frequency
formulation                     does       not.        Nevertheless                   the     latter           predictions
are        to       be    considered              strictly                supplementary                 in     any       instance
where           predictions                 can       be    obtained             with        the     low       frequency
pro c edure.
                                                            _0          co                             cO          _r_
                                                                                                                       @


                              â€¢-    Ox                      Ox          OX                             0"_         cO
                                    V                       v           v


                                                                                                           â€¢       @             â€¢        @             â€¢


                                                                                                       Ox          cO          cO        _-       _0



 0
.r-I

 a_

                          I                                     00_              _4_    od     0        0          O_          ,--       E'_      ,'-
                                                            â€¢ l_l            â€¢    @      @         â€¢   â€¢ 1"_           â€¢         â€¢            â€¢         @

                     Of             0        E_- _r_                                                               ._-         od        _-       0
 0                        I
                                    ,1-
                              o'j




                     Â¢)
       v                                                                                                   @            â€¢        â€¢            â€¢         @

                              cOCO           _    Ox   0                                               _-          _           cO        ._" _0
                     I0   !   _-  OX         cO   _0   _0                                              ,--         _           _'_       _,.0
       .n

       1    â€¢
.r'l




                              _0        Ox   OX aO     _0                                              0           '--         .._-      I,_      C_
                                                                    @        â€¢     â€¢     @         â€¢
                     I0
                                                                                                       â€¢-          0",         E',.- _0           L._
  0
.r't                 0

 0




                                                                                                        u'_        ,,4D _0               ,-        E_-
                                                                                                               â€¢           â€¢         â€¢        â€¢             @

_d                                                                                                      â€¢._-       O'x         l'_'X oO
                                                            .0           0       ,-"    ,1.   ed        0          0           '--   "-
                                                             ,--         od      i,r_   ,.,_- _




                ,H

                0
                                                             â€¢--            Od   i'_    ,._-   ur_      ,--            od      I_'X .._'           U"X




                _0             0




                                                                        -164-
5.5      Understandin_                       Sidewall             Transmission



Appendix            D     contains            a     copy        of     the     predictions                      for    Run         10       (the

case     of        blade         downsweep).                    There         are       a number                of    interesting

things         about           the     results             that        lend        to    an       understanding                     of       the

physics            involved            in     the        transmission                   of     propeller                tones.               For

instance,               the      top        five     contributing                   modal          pairs             are     all        of

the     following                type:         I)    either            the     acoustic                and       structural

modes         are       both        resonance              controlled               (or        nearly            so),        or     2)       a

resonant             or    nearly            resonant             acoustic              mode       is       coupled           to        a

nonresonant                structural                mode         (exceptions                  mainly            confined               to

the     Ist        harmonic).                 In     no       case,       however,                is    there           a    single

dominating                pair        of     modes.             In fact,            the        five         highest            contrib-

uting         pairs        are        responsible                 for     only          47.9%          of       the     acoustic

energy         in       the      cabin         at    the        I st    harmonic.                  This          value        rises              to
59.3%         and       58.0%          for     the       2rid and         3rd       harmonics,                   but        then        falls

to     only        24.9%         and        28.1%        for      the     4th       and        5th      harmonics.                      Thus

the     propeller                tones         are       being         transmitted                 by       a    rather            large

number         of       modal         pairs.             The      impracticality                       of       the     idea        of

moving         modes           around          in    frequency                or    changing                 the      wavenumber

coupling             to    affect            noise         reduction               is    evident.                    However            this

"modal         insensitivity"                       Is     no     doubt        part          of    the          reason         that          the

predictions                   are      as    good        as     they      are.           Furthermore,                       the     re-

sults         make        clear         that        improved            sidewall               treatment                will        remain

the     one        particular                topic         of     greatest              need       if        further           reduc-
tions         in     cabin           levels         (arising            from        sidewall                transmission)

are     to     be       achieved             in     these         types        of       airplanes.
6.0    FINDINGS AND CONCLUSIONS


The comparisons        in   this     report      have led        to a number of           findings,
the   most important        of     which      are reviewed        below:

       I)   In the case of the scale-model    tests,   the PAIN program
            made unbiased predictions.     The standard   deviation   of
            the errors  was about 4 dB (case of "a heavily       damped
            trim panel"  after             excluding       the    extraneous        low      fre-
            quency datum).
       2)   In case of       the     flight      tests,     the    predictions         with         the
            preferred     "low frequency    formulation"     showed a bias
            (on the high side) of between 2.6 and 4.3 dB and the
            standard     deviation   of the errors     ranged between 2.4
            and 4. I dB. Predictions        made with the "high     frequency
            formulation"      showed no bias but had a high random er-
            ror as exhibited       by a standard deviation      of 6.3 dB.

       3)   Predictions          made for       given     harmonics        at   different
            flight  conditions were found to be biased but the lev-
            el of random error  was extremely    low as exhibited by
            the small standard  deviations,   indicating  that changes
            occurring       in interior          levels   caused by flight                  recon-
            figuration        are being         predicted   by the model.


All of the above findings        are based on increasing         by 4 dB, the
ANOPP free-field     predictions    of the pressure       amplitudes      to
account for fuselage       surface  reflections     (rather    than 6 dB as
originally    programmed in the model).         Scale-model      blocked
pressure   measurements imply that surface         reflection       effects
dissipate   faster   (as one moves away from the propeller              plane)
than the PAIN model admits.         Thus the computer generated
blocked pressure     field    may be "stronger"     than it should be.
This may be offset       somewhat by the use of the so-called             ANOPP



                                              -166-
method 3 predictions       which lead to a "weaker"      exterior     field
than would be predicted         using ANOPPMethod I.      Ultimately,       the
blocked pressure      predictions     by ANOPP are needed to resolve
the difficulties,      because regardless     of the amplitude      uncer-
tainties,      there are virtually     no data available    to allow com-
parisons  of phase differences  between the free and blocked
fields.   The PAIN program presently  uses the free field    phase
data (without  modification).   Future changes in predictions
that might be realized                              when the bona fide                               blocked           field         is
used are unknown.

6.1      Use      of    the        PAIN        Program

PAIN     predictions                made           using        ANOPP        Method              3     propeller              data

should      be       adjusted             downward              by3         or     4       dB.        The        resulting            num-

bers      should        be     considered                  the      basic          estimates                 of    the        space-aver-
age     levels         in     the       cabin.             Keeping           in        mind          that        random         errors          are

going      to     be    present,               a    one-sigma               band           of    about           3.5     dB     about        the

adjusted          computer              predictions                 will         then           give        estimates            of       levels

within          which         about        2 out           of    3 of        the           flight           measurement               data
should         fall.         Approximately                      I out        of        3       should        fall        outside           the

band      (hopefully               by     not       much).             As    time              passes        and       more      flight

comparison             data        are     made           available,               this          technique               may     need        to
be     revised.



Calculations                made        using           the     high        frequency                  formulation               should           be

carefully            scrutinized.                       Although            no     bias          was        indicated            by       the

hypothesis             test        on     the       four        harmonics                  2    through           5,     it     is    pretty

obvious         from        Table         25       that       for      harmonics                 3     through           5,     there        is

a bias         (an     under-prediction)                         of     more           than          4.5     dB.         This        is    prob-

ably      caused        by     not        including              enough            modes             in     the     summation              in
Eq.     (16)      of    Reference                  I.      Future           validation                    work      should           confirm

this.

6.2      PAIN        Validation                Status

The     propeller             tone        prediction                capability                   of       the     PAIN        program           has



                                                                -167-
been validated                to the       extent         that,           at the          conclusion            of the
present study, no significant                               changes to the PAIN program have
been shown to be warranted.                               It is felt  that the present model
is "hamstrung"        to a certain    extent by the need for ANOPP pre-
diction    capability      of the actual    blocked pressure     field on the
 fuselage.     Eventually,      given this information,      the PAIN pro-
gram can be modified         to include    effects    such as synchrophasing.
In order to perform such calculations,              the PAIN grid will    need
 to be extended to cover the entire            periphery   of the fuselage.
The length of the grid should be extended at that time to allow
predictions    to be made for cases having high tip clearance   to
propeller   diameter   ratios.  Some consideration should be given
to reducing    the grid spacing at the same time.

The cabin            trim model is simple                          yet    somewhat sophisticated.
Stiffness            of the trim panel is                          not    taken into account nor                           are
details regarding  trim installation   included.    However, the
model has been found to be essentially      adequate over the lim-
ited    frequency     range from, say, about 50 to 1000 Hz.           Above
this range, sound isolation            will    be over-predicted   because skin-
to-trim     vibration     transmission      will  lead to increased   internal
radiation.

Noise       Reduction

The     PAIN        program      has      noise         reduction               prediction             capability.

However,            the   quality         of     the     predictions                  has    not       been     fully           in-

vestigated.               Studies         undertaken                in    Appendix           E    of    Ref.         (I)   were

extremely            limited.            The     poor     results               shown       in    that        work     are,
however,            expected        to    be     typical            for     frequencies                where         the   cavity

modes        are     driven      in      the     stiffness               controlled              region        and     where

the     trim        transmission           is     dominated                by       the   mechanical            vibration

path        (see     Section       2.8     of     Ref.         6    and     Eq.       A.22       of    Ref.     I).


It     is    felt     that      the      noise     reduction                calculation                option         in    PAIN

should         be    removed        (perhaps            made        into        a    separate          program)            so



                                                         -168-
that     the    propeller      prediction              capability        is    allowed         to   stand
alone     (at     least   until       the     extreme         limitations           on   the    use    of
the     noise     reduction         section       of    the    program        are     clearly       de-

fined;      for    instance,         the    use    of incomplete              modal      files      must
be    avoided).

                                           REFEREN      CES


 I.     Pope,     L.D.,   Wilby,    E.G.   and           Wilby,      J.F.,   "Propeller               â€¢Air-
        craft     Interior    Noise    Model,"            NASA      CR-3813,    1984.

2.      Wilby,   E.G.   and Pope,   L.D.,                "Propeller           Aircraft   Interior
        Noise   Model,   Users'  Manual                 For Computer           Program,"    NASA
        CR- 172425,    1984.

3.      Pope,   L.D.      and Wilby,  J.F,,              "Band-limited           Power  Flow into
        Enclosures,        I," J. Acoust.               Soc. Am., 62,           4, 906-911   (1977).

4.      Pope,   L.D.      and Wilby,   J.F.,             "Band-limited              Power  Flow        into
        Enclosures,        II,"  J. Acoust.              Soc.   Am.,   67,          3, 823-826         (1980).

5.      Pope,   L.D.,  Rennison,     D.C.,   Willis,    C.M.  and Mayes,    W.H.,
        "Development     and Validation       of Preliminary     Analytical
        Models    for Aircraft    Noise    Predic%ion,"     J. Sound    and Vib.,
        82, 4, 541-575      (1982).â€¢
6.      Pope,   L.D.,    Wilby,  E.G.,   Willis,  C.M.   and Mayes,    W_H.,
        "Aircraft     Interior   Noise   Models:  Sidewall    Trim,   Stiffened
        Structures,      and Cabin   Acoustics   with   Floor  Partition,"
        J, Soundâ€¢and      Vib.,  89, 3, 371-417     (1983).
 7.     Martin,    R.M.       and    Farassat,          F., "Users'     Manual    for a Com-
        puter   Program        to    Calculate          Discrete    Frequency     Noise   of
        Conventional          and    Advanced          Propellers,"     NASA   %_Â¢ 83135,    1981.â€¢
 8.     Zorumski,    W.E., "Aircraft   Noise   Prediction                             Program       Theoret-
        ical  Manual, " NASA   TM 83199,   1981
        Magliozzi,       B,, "Acoustic   Pressures    on a Prop-fan   Aircraft
        Fuselage       Surface,"  J. Aircraft,     19, 2, 104-111   (1980).

        Bendat,    J.S.  and Piersol,    A,G.,   Random   Data:                           Analysis         and
        Measurement     Procedures,   Wiley-Interscience,                                New York,         1971.
11.     "Prediction    Procedure  for                  Near  Field   and         Far Field    Pro-
        peller   Noise, " Soc. â€¢Auto.                  Engr.  AerosDace           Information      Re-
        port   Iâ€¢407, May  1977.
12.     Anon.,  "Prop-fan    and Gearbox                  Near   Field    Noise            Predictions,"
        United  Technologies/Hamilton                     Standard     Report             SP15A77,    Rev.
        A, February    1978.
                    Appendix         A



    â€¢ Analytical          Modification   of   PAIN

    â€¢ Program      Changes

    â€¢   Control    Card      Changes




/




                             -170-
                                      Analytical                 Modification                       of    PAIN



 The     basic           results             of     the      analyses                   presented               in    Refs.          (I)    and

 (6)     inadvertently                       lead       to       errors             in       the      calculation                of       the

 fuselage            loss         factor           _,        i.e.,             application                    of     the     results
 directlY            to       the      fuselage              of          Figure           I,    without              modification,

 leads        to     a     calculation                  of       _        for       a    case         where          trim       is    in-
 stalled            not       only         on     the       cabin             sidewall              but       also        the    floor.

 Also        there         is     a    failure              to       properly                take        into        account          the

 fact        that        significant                   modal             energy          of     lower           order        structural

 modes        can        be     in     axial           and       circumferential                          stretching                 motion
 of     the    skin           (non-bending).



 Consider            Fig.         I of          Ref.        (6)          and       refer        to       Eqs.        (In),       (2a),           and

 (3)-(6)            of     that        paper.               Note          that          if     trim       is       not     installed

 over        a portion                of     the       surface                area       (such           as     the       floor),          for
 that        portion


                                                       Cp    =       I    ;        Cp    =     O.

                                                       Cw    =       I    ;        Cw    =     O.


 Let     X    be     the        set        of     all       points             lying           on     the       structure             surface
 covered            with        trim,           and     let          _        be    the        entire           surface          area       (all

 points).                Eqs.         (In)        and       (2a)          of       the       paper        can        be    written          as




  8(_'-_)+c.G(_/_';w))"I(_')dE'


 and




(f(5(_-_'
   _
         )+_2cpGp(_J_, ;w))pi2(_)d_
                                  = -p_2CWfGP (_/_,;w)wI(_)d_ â€¢
                                                                                                              ,_                                (2a)


 In     the    present                circumstances,                          C w and          Cp    are        replaced             by

                                      CwH(_/X),                                          cPH(_/X),


                                                                     -171-
where


                                                                                              OF   POOR    QL_ALI_'g
                                E(_/X) = 01 ;
                                            ; X /X
                                              E ( X




Note    that      since        Cp     and      Cw       are       nonzero,             no     change      in   the     manner
that    they      are     handled             in    the       analysis             is       required.          The     fact
that    these      terms        are         discontinuous                   at     the       boundaries           of   the

trim    covered         areas        is       of    no       consequence.



Substitution            for     Cw     and         Cp    in       Eqs.      (la)        and        (2a)   gives




       (8(E'-_)+CwE(E'/X)G(P./}';_)).I(E.)dE.

                                                                                                                       (la)
                                            : /._(PJE,              ;,,,)(pÂ°(E,         )-%pia(E, ) )d_'


and




   (8   (E-E')     +p_2CPH          (E/X)     Gp (E/_:'           ;_)   ) pi2(_:   ) d_


                                          =   -p_2CWfGp(_/E'                       ;_)w I (_) dE                       (2a)



Consider         the    left        hand       side          of    Eq.      (la).           Let




                                    ._(E) = _                 ts_,S(E).
                                                         S


Then




                                                                                   S



                                                              -172-
                     s



                                                           ')Q(2/2';_)d2').




Now




                                                       m    MnYn(_)



Thus   the   left-hand          side     of   (l a)    becomes




             =   _       _s (@s (_) +Cw_@n(x)_              n(_')

                                     â€¢   JX"*
                                            _'        MnYn(_)




                 s                               m    MnYn(W)




Now




                              ro/,
                                n                            { Ms      ; ==s
                         .@                                    0       ; n_s




                                                 -173-
                                       6_    _:,_;         â€¢


                                       OF         POOi:,__;,.-:!../


                                                                                                                                  above
In    the    referenced                      paper,              it      was         an    oversight          that        /X

was     evaluated             as            f.Q       â€¢        Note        if        X =_,




                            E(_u(_)/MnYn(_)                                 )f       m_(R'          )_,,s(_, )d_'

                              n                                                 _X
                                      = _S(x)S_sYs(_)                                     =    #s(_)IYs(_)             â€¢




This      yields            for        the           left-hand                  side

                                  i




                                       S




which        is       the    result                  in        the       paper.


It     can    be       seen           that           the        actual           result             should    have         been




             E    S                                        _X


                                                  +E_S_                   c_n(_           )/mMnYn)/xm_S             (_ , )_n(_,    )d_'   .
                                                      S              n




Let


                                                                                                X
                                                                                              M s         ;   n=s

                                                                     )4'                              X
                                                                                              EnsMs       ;   n   _   s     .




                                                                                     -174-
The     above       becomes



                                                                                               OF POOi'_C:./:
                                                                                                            ,.:i;


                         S

                                                 +__s_n(_)                               Cw(ns M Xs/_4nY n

                                                       S            n
                                                       (_.)

                                                                         \

The     laat       term        (double         sum)        can          be understood              as   coupling          of     the

structural              modes       introduced              by          the    trim       installation.


it    is    reasonable              to    expect           that          for       all    significantly                trans-

mitting         modes          (i.e.,      those           that          are       largely        shell      as    opposed
to    totally           floor       modes),          that




 and       that        for    those      modes
                                                Nm




Assuming           this        is   so is       equivalent                    to    assuming          that    the       double
sum     can       be    neglected,             i.e.,           that          damping        of    structural            modes
through           intermodal             coupling              is       insignificant              because         energy
 flowing          out     of    one      mode    to        another                will    be     replaced         by    energy
 flow      into        the     mode      via    yet        a    third             mode.        This     assumption          re-
 duces       the       left     hand      side        of       (la)          to




                                 "_( 1*(cw"__ (_)))_s@S(._)
                                    S




                                                                 -175-
where                                                                     ORIGINAL PAGE iSl
                                                                          OF POOR QUALITY.

                                         ms = mMs/MX



Continuing,          reconsider          (la)    which         leads     to    Eq.       (6)    of    the   ref-
erence,         in   the     present      circumstance             (6)    becomes



          -Yr (I+(C_rY            r))Mr_ r +F        r    -    cFri        =       '_
                                                     Pr         P P2                    Pbl


Thus    no     significant          algebraic         changes          appear.


Now â€¢consider          Eq.       (2a).    w1(_)      is    replaced           by    the       modal    sum,
(2a)    is     multiplied          through      by    Â¢r(_o       and integrated                to    obtain:




    __r(Â£,)_(6(Â£-_')+pJcP_(Â£/x)Qp(_Â£,
                                    ;w))p_(Â£)dÂ£dÂ£

                                                                                        S



This    reduces        to




                                                                           _       2 cwVI       rs
                                                                         = P_            ZD          _s .

Fol!o_ring       the    analysis         in   the     reference,           the      above       can    be
shown     to    lead    to       a modification           of    Eq.     (i0)       of    the    paper,      i.e.,




                             =       C_r)"
                                         CPpw2_nAf  '(n '                f $ n2 (_) dE
                     brn                  V(_n2 _ k 2)                   JX




                                                      -176-
Other       than          this,       there            are     no     Changes.



It    follows,             that       as      a    final            conclusion,             the-structural"loss

factor         _r     should          be      given           by     the     result




                           (rl_,)2. = ICw,2--2__
                                         I/mrOr 2c_  -2 + Zl2r
                                                  wU#_r

(Note       that          the     new        variable               mriS     used        only     within          the     context

of    the       calculation                  of    U_).



A    question             might        now        be        asked      as    to     whether           the    trim        coverage
is      correct           as     related           to        the     prediction             of    transmission                  through

the      trim.            The      answer          is        "yes",         because         thepresence                  of     trim        on

the      sidewall               and    its        absence            on     the     floor        is     accounted              for     in

Eq.      (52)        of     the       PAIN        model            (Ref.     I).         Note     that       the        trim     trans-

mission             coefficient               Tt(=ICWl2)                   multiplies            only       One     of    the        two
 terms         in    the        braces        of        Eq.        (52).       A    bar     is    placed          over         the     f,

in      _'(n,r)           to      distinguish                 it      from     the       term     f' (n,r)          (no        bar     over

f)      with        purpose           being            to    limit         trim     to     sidewall          and        exclude         it

 from       the      floor.




                                                                       -177-
                                         Pro _ram            Chanmes


All    recuired        programming             changes             to    PAIN      and     its      subroutines,
or    to    auxi!iar7        programs,             are       specified           below.




           I)   Changes       required             to    calculate              the   modified              result

                for    _     as    found       in       this       appendix,          letting

                            MX=GMASS(IR,            2)       ; Ms=GMASS(IR,              I)    :        \

                Subroutine          ETASTR
                     Line    47    to    become
                       _,'._=AIMAG (CW) *GMASS                    (IR, 2)/GMASS          (IR, I) â€¢

                     Line    50    to    become
                       C:,_0D2=REAL           (_.0 D2) * (GMA_S             (IR, 2)/GMASS               (IR, I) )** 2
                                                                    o-




                                          â€¢    j



           2)   Changes       required             in    the       calculations               of    f'(n,r)           and
                _'(m,r)       af    Eq.        C52)      of    Ref.        (I)     related          to      misinter-

                pretation          of    sign       convention              used      in      the       program       _.[RP:

                Subroutines             TONE       and       _ED

                     Line    107    of    TO_           and       Line     79    of   _FRED        to    become
                       rim2= (FQM(iQ,M)*                 (FINS (N I, IR)-FINP(N                    I ,IR) ) )**2

                     Line    111    of    TORTE to            become
                       Din2= (FQM (IQ, M)* (FINS ([_I, IR)*SQRT                               (TAUE)-FINP            (N I,
                       zR) ))**a
                     Line    8_    of    _TRED to            become
                       E_R2= (FQM (I Q, M)* (FI_S (?[I, I__)*SQRT (TAU)-FI_P                                       (N I,
                       nR)))*-2

           3)   Caanges        required            to    limit           blocked      _r_ssure              amplitudes
                of    propeller          field          to    a    h dB     increase           o'_er        free     field
                levels:



                                                                                ORIGINAL PAGE I_"
                                                                                OF POOR QUALITY
                                                         -178-
     Subroutine              PROP

       Line          49    to     become
            REFL=(10.O**(O.3-O.000224*EXP(O.O8*GAMA)))*0.8



4)   Changes          to     prevent         printing           truncation           of    large

     values          of    generalized              masses          for    narrow        body

     fuselages:

     Program          PAIN

       Line          379     to     become

            6005          FORMAT         (TIO,I3,F8.2,1X,A5,Fg.5,I4,I3,

            F7.4,I4,F7.4,F9.2,F8.3,F8.3



5)   Changes          to     allow         propeller           input       data     to    be    of    the

     form       of    that        for      blade        downsweep          only:

     Program          PAINo
       Following                the      Comment        Card        "C...Propeller              Data",       add
            C         INPUT         DATA     CREATED           WITH       ANOPP     TO    BE    BLADE

                      DOWNSWEEP             ONLY

            C         PAIN        WILL      CREATE        DO_'_S_EP           OR    UPSWEEP          USING

                      ANOPP         DOWNSWEEP

     Subroutine              PROP

       Line          _4    to     become

            DELPH=2.0*B*IH*ALPHAL(L)

       Following                Line       63:"24        CONTINUE"         T insert        12    Cards
            IF(ROTN.EQ.+I.0)                       GO   TO     30

            DO       29    IH=I,NHARM

            DO       29    K=I,NK

            DO       29    L=1,10

            LU=L+9
            LB=11-L

            PX=PMH(K,LU,IH)

            PY=PMH(K,LB,IH)

            PMH(K,LU,IH)=PY



                                             -179-
                        PMH(K,LB, IH) =PX
                                                                     ORIGINAL        PAGE      _
                 29 CONTINUE                                         OF POOR         QUALITY
                 30 CONTINUE


Program        MRPMOD


          I)    Changes       to    allow           acceptance            of    increased          eigen-

                vector      output        by        M/_P    (40    instead           of   30   eigen-
                vectors)

                   Line     13     to    become
                        C...MTOTAL=HIGHEST                    VALUE        OF    M    CONSIDERED        (MAX 15)
                   Lines      I_    and        16    to     become
                        C...FOR         EACH        VALUE     OF     M    (MAX       NMODES=20)

                        C...NMOD=2*NMODES                    (MAX        NMOD=40)

                   Lines      64    through           67

                        DIMENSION         STYPE(2),TYPE(2,5),FREQ(40),TYP_(2),
                        NMODE(40),
                   I      DMAX(40),COORDS(41),COORDP(41),DISPS(41,3,40),
                          TMODE(_0,5),
                   2      DISPP(41,3,40),GENM(6,40),GENMAS(40),DUF_ff(700),
                          NA(700),
                   3      TITLE(16),NORD(700)
                   Lines      68    through            70
                        DIMENSION         EVALS(72),MVALS(40,15),NVALS(40,15),

                        EVECS(40,15),
                   I      MVALP(40,IO),NVALP(40,IO),EVECP(40,IO),MVLS(40,

                          15),NVLS(40,15),
                   2      EVCS(40,15),MVLP(40,10),NVLP(40,10),_ICP(40,

                          IO),TYPP(40)

                   Lines      7 2 through              74

                        DIMENSION         FR(40,15),TYP(40,15),GMASS(40,3,15),
                        MVS(40,5,15),

                   I      NVS(40,5,15),EVS(40,5,15),MVP(40,3,15),_VP(40,
                          3,15),_-_P(40,3,15),

                   2      DIS(40,41,15),KTL(2)

                                                      -180-
                                                                       ORIGINAL      PAGE f_]
                                                                       OF POOR       QUALITY
                              Control    Card     Changes

i)   Control      cards   for MRPMOD       showing    required          DEFINE     statement
     needed      to create   direct       access   permanent           file.

         /JOB
         PAIN,    T 400, P I.
         /USER
         / CHARGE
        ROUTE, OUTPUT,     DC=PR,       UN=*,   ST=**,    FID=POPE,     DEF.
         DEFINE,TAPEg=STRSO.               "
         GET, MRPMO D4.
         ATTACH, TAPE7=MRPSM4.
         ATTACH, TAPE8=MRPAM4.
         GET, MRPMO D C.
         COPYBF,MRPMODC,LGO.
        LDSET   (PRESET=ZERO)
        L GO, PL= 50000.
         GOTO, SU_ARY.
        EXIT.
         SUMMARY.
        DAYFILE.
        /NOSEQ
         /FOR
         /READ,    MRPMO    D4
         /ZOF
2)   PAIN   control    cards    (modified   program    PAINM)              showing       use    of
     structural     modal    file   as direct   access    type.

         /JOB
         PAIN,    T400,    P I.
         /USER
         /CHARGE
         ROUTE, OUTPUT,    DC=PR, UN=*,         ST=**,    FI D=POPE,    DEF.
         GET, PAINMD4.
         GET, TAPEI I=CYLSO.
         ATTACH,TAPE9=STR50._--Direct                    access   file     to    local    file
         GET ,PAINMC.
          CO PYBF, PAINM C, LGO.
         LDSET (PRESET=ZER0)
         LGO, PL= 50000.
         GO TO, SUMMARY.
         EXIT.
         SUMMARY.
         DAYFILE.
         /NOSEQ
         / OR
         /READ,    PAENMD4
         /EOF



                                          -181-
37   CYL2D    control    card     change     required    to   access    the   Inter-
     national     Mathematical        and    Statistical      Library     (IMSL)
     subroutines.

           Instead       of

                   ATTACH,       IMSL/UN=LIBRARY.

            Use

                     BEGIN,   IMSL4,     IMSLCCL.




                                            -182-
                          Appendix         B


                SCALE    MODEL     PREDICTIONS

         @   Structural          modes     list     (partial)

             Acoustic      modes         list     (partial)
             Modal      distributions


In   sequence     for    the     3000,     4000     and   5000      rpm   runs:

         â€¢   Propeller         noise      data     (Ist   3 harmonics)

         â€¢   Interior       predictions
         â€¢   Highest      modal        contributors           to   interior       levels




                                   -183-
                                                                                                "                       i



                                                                                                                                                                             ORIGIN_ _L PAGI_ l_r
                 :                                                                                                                                                       OF P0C R QUALITY




                                            I II           i 'I            I _I                  l        II        I +I            I     !I           I            I    I 'I                 O 'I                I         II        I I               I _I                 O        II       I       :I           I           I   I       I    I        'I            I            _I        I           I        I           _I               I       _I               I          [I                  I          l
                         I                 uw_            _u_             w_                                       WuJW_                              _                 _W                   _ _                 _                   u_                _'_                                             W           _        _               _   _                      _             W        _            _       _            _               _                        _           _               _




                                                              .................... .... ............
                                                                                                 i.......
                 ',,+It,,-.                O_             _               _                     _                  Om               N4"               _                 IO                   _,i                 Oi                  _p_               _         _           _1_               _       I           _,_                      _   _         _            4"            _        _,_ _                4"           _r_             _.r_ _                   _           _               _          _

                 :    ---:;                  oto              o+o             o+o                 olo               o,o              ore                  elo            o_o                     o,o              o|10       o,o                           o:o                o5o                  o,o              o,o             â€¢       â€¢     o,o                      o,o                         oto            o,0                        e,o                         ole                         â€¢
                 _--.                      ..*_i..,..*+                                         ,=,_                    .._..,..,                               I           ,'*"''_                                  I,"_"*"                                                     I"_                                                            _'                     _                                  I        ''=''e                                                            I                          "

                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     L

                 _       _         â€¢         O       O        O   I   O       O     I       O        O         O    O   _       â€¢    O    r       O       O         O    _       ,       O       O   _       O    O              O    _       50           O     I       O    O            â€¢       O   I       O    t       i   O   O       O       â€¢     5        O       O              â€¢        O           O        O       _       t        O       I       O           I               O           O              O




                 ;" ,+L...+.,+I..o.+..L..--.-,+
                 ,.,.,_,,,,.               ,,,_k,,,_oc:,o_o_ooo_p,,,c:,,,0oI_e,,,,loo,,o,,oo_l_mm_                                                                                                                                                                                                                                          _i_m_O_m_m
                 eig_:                        ol*        .,o         o,o        el*       *_0        e,.      olo                                                        0,0                     *,o              el*                     0,*              0,*                olo                  o,o                  *       *       *    *     el*       *     *     *10         o,*          *_*                                                                            *t0                     *              *
                 ,      I.D                _I*Ip.I_eIIII_eII_eIII_eI.I_ji._meII_mI_.I_j_e_eIe_._It_I*_I_I___m_N                                                                                                                                                                                                                             _lleI,IOtm_I*I_eie_Ie.l_eI_lIl_t*l_l_._i,IIg_liJl_'ll


                                                                                    i                                   ,                     i                                      !                   ,,                                                      i                                         ,                                              i                                                                     I
                                                 L                                  d                     L                                   '                 _                    I                                      L                 I                  I                                                                                                                            "L                                                         '                           L




                 IIn4_lt)          i         dlJl_            OIO             I)_40                  QI        â€¢    â€¢           â€¢    OId_                 Oil)               OIO                 OIO              OI4)                    â€¢        â€¢       Ol1_               I+l_                 _;_              o+_              â€¢      â€¢           E),_             mIO                           O_O              elID                     _,_                             _I_                     e,4
                 "                               _                ,." ! ...,Irat_                                                             ,m _o.-                                                                       I"                                I              I                 _                                    I       t                          Nit                         Oll                              i                    .t                          I                          '
                 _.-                       .,.....,.....,.....,................-,-....,..
                             m_i                                                                                            .                 ,


                                   i       4"_l_,N_D_,Or-,o_-._D_*I_4"m_**,Op-_m_                                                                                                                                                                                                      .*Â¢I'M*_r*,._O4"_'-._'_'.I_I_._'_I_N_



                 i.ll                      O_OOO(O_                                                                4004"k_(mNO                                                                                   4"_NN                                 OO_                             D14"                        m(Â¢                      @    O            _W                     (N_                           _O                           Ok                       _               _           _          f

                 ,,,
                 nu_;
                                            ,I;
                                            â€¢  t    â€¢
                                                                  ?   â€¢       lio
                                                                                    I                â€¢
                                                                                                          I;   â€¢    â€¢    â€¢  eli
                                                                                                                                    ,,                 ,IÂ¢â€¢         â€¢        o,t
                                                                                                                                                                                     , ,,,       e,o               â€¢   â€¢
                                                                                                                                                                                                                            I',           â€¢        â€¢    I,i
                                                                                                                                                                                                                                                                         ,    â€¢
                                                                                                                                                                                                                                                                                       I
                                                                                                                                                                                                                                                                                        t   eli
                                                                                                                                                                                                                                                                                                I'
                                                                                                                                                                                                                                                                                                                     o+o
                                                                                                                                                                                                                                                                                                                    I '1            '
                                                                                                                                                                                                                                                                                                                                        â€¢
                                                                                                                                                                                                                                                                                                                                                  '
                                                                                                                                                                                                                                                                                                                                                    â€¢
                                                                                                                                                                                                                                                                                                                                                              '
                                                                                                                                                                                                                                                                                                                                                                â€¢              i+l
                                                                                                                                                                                                                                                                                                                                                                                     ]
                                                                                                                                                                                                                                                                                                                                                                                                       â€¢
                                                                                                                                                                                                                                                                                                                                                                                                           lle +'+
                                                                                                                                                                                                                                                                                                                                                                                                               â€¢     â€¢                  â€¢        o_t
                                                                                                                                                                                                                                                                                                                                                                                                                                                                             'I" â€¢               t       I_q
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                I'
                 =C                                               i                 I                                                                                                        .                                                +                                                                                                               _                      +                                              '



                 : .- .L...,......,+..L-+...L....+,+..-...,..,,.L.+++.I+.,,
                                   :             L                "                     :                                   "                 : L                                    +                                      L                     +                  '                                     +                                                  I                                            L                                                 :                           |

                     --:,m[                O_OOOJ_O                                                            ,,*_.*OOOO_OOOOO_                                                                                                     OO                OOO                             =DO0000                                                   OOOOO,_OOOOO_O                                                                                                                                                 ''_
                          ILL.              gill   eiO                        9le                    â€¢          â€¢     olo  @qo                            oil+               â€¢           â€¢       olo                  eli             *+o               0,0                       â€¢    *   *    *                       *,o             â€¢         I+*    ole   â€¢                                               I            â€¢               â€¢        â€¢               â€¢           ole                         ore
                                       i         /                                      :                            â€¢ ;     ,                                /                      _                   :                  /                               ;                                 '                                                              i                                                                      :                        i                           /

                     '                 _ L + '                                                                              '                 '                     I                + + I                                                        + +                                                      :                    ,                             i                      I                                              + + I



I   IU   II,..
             I


                     ::!!i)!!!
                          !!i!!!!''"
                                 !!i!iiii                                                                                                                                            I                   :                                                           !
                                                                                                                                                                                                                                                                                                                   z                             _
                                                                                                                                                                                                                                                                                                                                                               â€¢ o




                                                                                                                                                                                                                                                                                                                                                               '


                                                                                                                                                                                                                                                                                                                                                               ,,,r I"_
                                                                                                                                                                                                                                                                                                                                                                               â€¢      +o




                                                                                                                                                                                                                                                                                                                                                                                      I


                                                                                                                                                                                                                                                                                                                                                                                      ko




                                                                                                                                                                                     i-              I+84.                                                                                                 +
                                                                                                                                                                                         i                                                                           t
         r                r       r           .r-




                                                                                                                        ORIGlt_
                                                                                                                        OF PO'




         ,.,   Z Â¸                                                                                     i
         f,D_ _,
         e,.,= tin,


             e,i     ,01                       !                  r       I                            :


         "=_
         u_q  "
             "=i                               i                  i       i                            '                 i
         e=i                  L                i                          I

             Wl               I

                     Z        I       i        _                          i                            i                  :
             ,L,,,-,
              â€¢ Zl                             i                   '      i                            i                  i
             e=;     ="=i                                          !      l                            .
                                                                   i                                   â€¢
             'nl -"_                                               i      I                            i                  :                                                                      i
             "_ "i                                                 !      I                            i                  i                                                                      !                                                                                                                        i
             '=(i             I
                     v                :                            â€¢      L         ,                                     I
     =Â¢-.,: u.                        ,        oÂ¢ oooooo0ooooo                                                  }ooooÂ©                         :Do,...oÂ¢=,c ,-ooo_oq                                                          _-,ooo_                           _o_--,,L-,_                         =o,=o_


     l             t82[i              i.m      ____W__          er m   _i _n e_ _          _    _    F,,,_
                                                                                                        _n e_ _     _     Ep _     _    e_ _         _     Â¢_ _      _       ,_T _         _     _       _       _   _       _r _     _       _       =, _      _, _--"       _     _       _       ,,, _, _       v- _


     _,o =
        ,,0_ = t                               _'e--
                                                  â€¢ '' .......................................................
     ..=...                           r        ,,',.-,-'-----.-----'---.-'-----------------'----


              mi&i_L;                 I     U..,e   ele          e,e    eie       el..,,              ere   e. le       e!o       e_*    el*             e!e       e,e        e_*              *,*           e,*         *    â€¢     =,*           *       *   *je   ele             *           *    â€¢   e.*        *


     W. t,u_          ,,'-,           i

 = _..==.                             1-            o              1          =                  '      .                 I         t                      I             '                           _           '                                    !               _             :
â€¢;   I=,.,,,"_;                                         |          i          i      /           ,      t      /                             /                           _ /                         !                        I           !                     /     i                             ,
     ,..=,-..
     &.= *-* u_ m
                  _                   _         :       /!1                          |           i      i      |          :,                 |             ;             =        |                  _                        |           !           =         |     *             =               i


                                                        r                            r                         r                                                                                                             r                                  r                                   r
     _u_ll_           _               U_l_d_,O      â€¢       â€¢    e;e    e,o       o_o          e,o    O,o   e)o         e_e       e,o    â€¢       â€¢       o,e       o,e        â€¢       ,e       o,o           o,e         â€¢    o     o,'e          o:o         o_o   o,e           o,o           â€¢ jo     e,e        â€¢


             ULIm
                                      i                                                                 :                                                                                                    "                            !           i                   _             i                      .




                                                                                                                              :                                !                                                                                                                                               !
                                                    Â°




                 )RIGtNAL   =AGE _;
                C,F POOR    UALITY




                             o.,,,o _,= 0oooo
                               i




           l                   !
                               I




           i


           i                   l




           ;
            I


                                                i
           .I
00000


                               1     ,    i
                               i     :    i
                               1


    0000         _000
i.



                                                                       :)RIGINAL       Y:: ._,+i




     Z
     O

     ID

     I=




     N.           Z

     m        Â¸   IJ
     m            ..,.


     ,,:, .?.
     I,&IL            ,it,.

     it.
     1.9 Â¸          â€¢
     I,I.I
     '_           I,D,
                  m



                  ll_ii
     II'_ Â¸       .,.I

                   4.




"..,p+ ,.




          â€¢                   â€¢   tt   â€¢   â€¢   I1   ql   ti   ql   â€¢      â€¢        _      _        _1   11   â€¢   t   It   â€¢
0mG_i_
OF       O_




     !=
     :   U

     !-.
     ! ,o




     l




         t,q




         I
         me



         E




         O




         II
               o.o.o.




                        ........
                        ..,.,,
                          -o
                           oo
                           i...,
                               ..
                                                                                                                                                                                                                                                                                                                                        _b                                !
                                                                                                                        ,.                      +.                                                        _. _-
                                                                                                                                                                                                              â€¢ +â€¢ +,
                                                                                                                                                                                                                    â€¢ +,-o
                                                                                                                                                                                                                       â€¢ â€¢ â€¢                                                  â€¢      ..â€¢ ,_,-,+
                                                                                                                                                                                                                                                                                          â€¢ o, â€¢ +â€¢

                                                                         .                                       -I      â€¢                      i'_       N'_ Ilml _                      I1'_ li't       i'l         IP_ Iml <P II'111"111_                              irl        iÂ£1         _Pi _              ii_0 t1_1




                                                                         i
                                                                                                                        "_:                     Â®
                                                                                                                                                          L.+.,.+.,+,,+..+L
                                                                                                                                                                      Â®+"'"
                                                                                                                                                                                                                                                                                                                                                                          "'TT'




                                                                                                                                                                                                                                                                                                                                            ogle                                              _
                                                                         i                                       BI_II_I                        I_d I1_                   fl'l    q4" I11111PlID"                     .        IIII, lull        Ill"..                   _l_ Ill                .4"       _        _       N




                                                                                                                        "                                 L                                                           L                                                   i          _P          I_        _        (4J I_
                                                                                                                                                                                                                                                                                                                                        _




                                                                                                                                                                                                                                                                                                                                            iâ€¢oâ€¢oeoâ€¢â€¢_oâ€¢ooâ€¢oo
                                                                                                                                                                                                                                                                                                                                                                 __II


                                                                                                                                                                                                                                                                                                                                                                                      "L
                                                                                                                                                                                                                                                                                                                                                                                                                __




              )F.PoOR                                     _U._ LI.TY                                             ._.                            _l..... _,_,-_. "'**" _._._._._.
                                                                                                                                                                            * ........ _i_
                                                                                                                        -                                 r                                                           r                                                   F                                                             ___l|


                                                                                                                                                                                                                                                                                                                                                                                      "L
                                                                                                                                                                                                                                                                                                                                                                                                                __




                                                                                                                                                      â€¢ to â€¢ -.,-                                               -1-                 â€¢ â€¢ â€¢ **I-                                           â€¢ * â€¢ * â€¢



                                                                                                                                                                                                                                                                                                                                        .+.L.....L++_+.L._
                                                                                                                                                                                                                                                                                                                                         . ._    â€¢ . . ._ .....                                                            _   .
                                                                                          :                      iilO       I,                  IIiI      i               0       fvq.            idt. On, 'lIp                _        _        _        ,dp Onl I,dp.                          fit       0.               lure
                                      i                                                   ,                      _          e,

                                                                                                                                                                                                                                                                                                                                        __T                                                    I   _            __




                        ,                                                                 _                      o.                   = ._..,o=.,L:++...,,L:o.,~_,.                                                                                                                                                                         illliâ€¢liilllllIâ€¢l




                                      ',                 P.                  ',           !                             ,-,,_                    -_ooo,_a,-I.-,_._o_._o._o.,.
                        â€¢                                _                                _                             _             u t             eL*                     â€¢       â€¢       â€¢       â€¢         el*                 â€¢        *        *       â€¢   el            e.       â€¢             â€¢       *        â€¢       *

                        '.                                    â€¢ _I                        i                                 *t                  _         _               _               I       I        _          _,-i_,,lO                                   _       _          m           _                  _       _



                                      '
                                                         l
                                                         P"
                                                             _
                                                               el
                                                                                          I
                                                                                          i
                                                                                                     _
                                                                                                     OI                          :                                    "                           i                                     i                 ,                                      :                                                               i        ,:          '            |+                      !
                        I
                                                          0
                                                                +
                                                                             I
                                                                                          I
                                                                                                                                                          L
                                                                                                                                                                                                                      :
                                                                                                                                                                                                                               "
                                                                                                                                                                                                                                        ""
                                                                                                                                                                                                                                                          "
                                                                                                                                                                                                                                                                          L
                        d                                Ill      l                       i         Ill                 N                       {I i                      i_I                     _                            _I_                                                   I           _i_                I{_             ,       Oâ€¢â€¢eâ€¢lolâ€¢â€¢oeelelI
'_                      i             i                  _            I                   ; _i,o:                                     .9              .to                     â€¢ * * . el*                                           â€¢ * * * .t0                                          â€¢ * * â€¢ *                                          ooooeoooâ€¢oo:oâ€¢,oooâ€¢




..if
 "
                        i             !
                                      I
                                                         w
                                                         IDI"_{I
                                                                             i            _ . .._ i
                                                                                          '   _i                                      __s                 I                                                            r4pliPimi"                                         l                                                             "                                      "'+r';                                      /
                                                                                                                                                                                                                                                                                                                                            Illllâ€¢llllâ€¢,llllil
+l,                     i             '                  /-                               : "_L_"                                     z               â€¢!â€¢                     ......                                   _â€¢ .....                                           Iâ€¢ .....


"0!                     ;
                                      '

                                      I
                                                  _t

                                                         _u_+
                                                                '_                         :.

                                                                                           +
                                                                                                             I

                                                                                                             lm;                      m         N             _ii         I-I     O       _       m        ii          _1      iI       m        ii       NII             _          e           O         N        N       N
                                                                                                                                                                                                                                                                                                                                        .                                                     .y,.,.                       !
         el                                              _ll_;                             ;                 /ll                      llt             elâ€¢                     â€¢ â€¢ â€¢ â€¢ elâ€¢                                           â€¢ â€¢ â€¢ o "lâ€¢                                          â€¢ e â€¢ o â€¢                                      _                         __'__




:_               -      i             I           =_OI                                     I                 I                                                                                                                                                                                                                                                                                -y"                          !
;                       ;                 i              _                                 "                 I_I                                      â€¢           â€¢           â€¢       â€¢       â€¢       â€¢         â€¢          â€¢        â€¢        o        â€¢       â€¢       â€¢         â€¢        â€¢             â€¢        â€¢       â€¢       â€¢           â€¢Iâ€¢â€¢â€¢IIIOâ€¢Otâ€¢â€¢â€¢â€¢I


                                                                                                                                                                                                                                                                                                                                        _                         _m__m                                              m__
    0                    i                I       _ll.                        _            I                 |                   '.




                                                                                                                                                                                                                                                                                                                                            â€¢â€¢lâ€¢Oâ€¢oIâ€¢â€¢â€¢eâ€¢oeel

    _L_.                i!            O.d_i_.=O,                                  NI!                        l_lil" lt'_
                                                                                                                       ;.,                       .            .           _       P"       P"     "        I.II                                  "I"                          IP_P"                        "        ""
                                                                                                                                                              I                                                        I
                        + ' "''=_-+
                                 ' "+Â°"
                                     '                                                                                                                        L                                   +'_ :                                                                                          +                                               ,                        _ i                      P !               !     I

    i                   i                 i              i_'l                              ;                 I                   1
                                                                                                                                                              /                                                        /                                  ,
;"                                                _-i                         I   i mi                       /Oi                                 OpN_P_N_NON_N                                                                                                                _P_NO0
                                                                                                                                                                                                                                                                                                                                            â€¢lliOlliOlllOlilo




                             --                                                                                                                  !ii!f.......
                                                                                                                                                        i!!o
                                                                                                                                                                                                                                                                                                                                                                                              _         |   |              l

II                          â€¢   ll_       0       ---I _-       ai            t   t.I                        /                   i




  o            I,,-      _   li=          _       Ii.    l=     I.            i   alil                       /                                                                                                                                                                                                                          m                                             .m_ll                                I
i               tl       md II            _              Uâ€¢                   I   _'                          Ill        â€¢
:..             ,',      mac              -r      --     m      u.            ,   "_i                        _N'


    -          .."-..-                                   +                    +--_                           i                                                                                    o                             oooooo                                                                      oOOO                        ooo_ooooo_oocoo_ooo
'-J             ,,.1:           mla-talt-li                                       ,..il              "lr_,                                                                                                                                            â€¢                                                         â€¢                       ooo_ooooo_ooooo0o_
                                                                                                                                                                                                                                                                                                                                         OOOOitI.OO_IIOIItlO

                                                                                                                                                                                                                                                                                                                                        ooo                       =ooo-oo_ooooooo_o
    II.        ill       U-" Ill          ill     I      Mii 'll              I   ladi               l.I         _      "i"      '                al                      _0      ITâ€¢      <P               l_i_                        O,l_

    ll
    i
                C==ICO._v,'.
                li  "3 I     "--I I'l                    I      I"l           I
                                                                                  Oâ€¢
                                                                                  i
                                                                                                     o,,..i.,I
                                                                                                     I.l I=l
                                                                                                                             !
                                                                                                                        ---I i                                            I_      I        ll'l             ZE                 "_=O00_                                                                      I_      N       I-I




                         '_l ,                                                                _|
                                                                                              !|I                                                             i                                                        i                                  i_il                               i
                         I_,itil!
i                d)                           â€¢                      â€¢                          â€¢                           â€¢               â€¢                                 â€¢                       â€¢                             â€¢                         â€¢                          â€¢                              â€¢
                                                                                           ORIGiNb, L
                                                                                           OF POO_:_




              16.




                           _L
              2
                                                E
                                     â€¢    o_o            â€¢   â€¢   â€¢            â€¢
                            .o


              :     ....
                    _.,
                                      J I              I I I            I
                           ii_ l_J   IJi.i
                                        LIGI          I.IJ
                                                         I.II,I
                                                            i_J         u.I
                           l.I_41,   _                t,,e
                                                         O. _           ft..
                           I.,-41,   ,.=t
                                        O-            _ _. i'_ _,_t
                                                                  ,=.e,=o

                                     _.                              *.-..
                                 i   rips en4         eml _) _J lan'4_m      '4"




Z_z                        "_ tl.    _,_ m      _,_,,_

                           E


          _   uu    u_




      i
      J
          I Â°Â°                                                                     -191-
      â€¢                     0   â€¢    IF       IP    â€¢           â€¢   â€¢   â€¢      â€¢      Q         â€¢    â€¢   _   _6   â€¢   B   w             w




                                                                            ...........
                                                                                     _" _-_A'
                                                                             :oOR _U




                                                   0_000
                                                    lille




                                                     ooooo




"i"i
                                                     ooooo

                                                                                                                                        _u
                                Z_
           'IF"


                                                                                                                                        i     z


           N

      L_                        _Z        O   _r




      "'I                                            ooooo

                                                                                                oi

      IA._-
                                                                                                                              Z         _
      --I 0           I_
                                                          e     '


                                                                                                                              _v
_fl lie
LU_                   It_
O._OZ
                                                   ooooo
LJ.            D,d L_
IN        O_

L_    "_B 4T



                                                        oooo_
'4[   Q        0..*
                                                                                                                                    â€¢    .,_ ,_
                                                                                                                                         C_I I,l,,,




                                                                                                                              "P.




      I

      !
      !
C
0
                                                                                                                            â€¢   _   â€¢   â€¢   â€¢   _




  R QUAL_TÂ¢

                                                            mN




                                                                  O
                                                                                  11
                                                                                       iiii}!i!                         â€¢



                                                                  N



                                                                            L

                                                                            O

                                                                  e_
                                                            O_
                                                                            I-

                                      O
                                      0                                     N

                                      g
                                             N
                                      0,Q
                                                                            O



(,.                                                                         I,M
                                                                            O


                                                                            N

                                              E                   f_
                                                                            1"         oeol       â€¢ â€¢ .,.â€¢ .w_":-
                                                        m   P.,, _!,



                               a,_            ,t
                                      Liu,_
                                                                  u_

                                      .a"_

                                                                       i                      m




I
                               _      uL,. 0

                                      OQ




                                                                                                   â€¢ -I. â€¢ .,)â€¢ ,,â€¢ â€¢ â€¢ ,
                                                   N




                                                   O        _N
                     i         i_     J.d     u-




                                                   Im
:Â¢I

                                                   N

                                                   IJ

                                                   Z




                                                              â€¢        ml
      â€¢"_ Â¢0   Â¢Â¢                             _-             _N
 ,c
&,L


      ,.I      ,.J       01.    _.3    _      _j




                                                                                                     -1

                                                                                  I
                                                                           9_                    _9 _+_                                                       _                                    ._
                                                                           _                                                   _dl                                         _                       III              I       I       I

                                                                           '             /                                                  fl                                     ''/
                                                                               â€¢    o_           â€¢       â€¢         â€¢       â€¢       oq                 â€¢        â€¢               â€¢   â€¢          oq         â€¢          â€¢       â€¢       â€¢



                                                                           _                 1                                 _                      I                    _                             I          I       I       I

                                                                                         /                                                  fl                                     ''fl
                                                                               eo                $oooo_eoeeoeoeee




                                                                                         /                                                  fl                                     ''fl'
                                                                               oo_eooeo_ooeeo_oeoo




                                                                                    -1                                                      _                      + ':'''Â°

                                                                                         I                                         _l                                      _*_11
                                                                                         /                                                  fl                                     L          I    I     I          I

                                               {                               IO                eoooo"otoeeqeeel




                                     g+                                                  /                                     ' U                                 i               ,:oo,,o,

                                      ._                                                 /                   '                               fl                    !                   .ililll:
                                     A      â€¢
t,k
&,,                                  .!                                    ___N_Â¢'_

2                                                                          _O___P,_
'11
m                                    _5    m

                                                                                         /                                                   /                     '                                ''"''


                                                                                                                                                                                                         TTTT

                                                         ,4_ ,,,IP

                                                                      Q.
                                                                                                                                                                   ;                                         Jill
(

                                                                                             a       â€¢       â€¢         â€¢            â€¢                     â€¢                                                  â€¢          â€¢       â€¢       â€¢
(
 (




                                I+"
 (


d
                                                              0                                                                     ._                    , .9 ......

                                                                                                 Ill                                          I T.                                      ''1              ....
                                                                                                                                                                                                          I , , ,
                       "                   _       '_
                                                                                                                                        â€¢                 eo
r     i                ,        I_    _.._ _       _

                                                                                                                                              _       _            l+              __                                                   I
                                                                                                             ''                                      I'I                                           J'''
                                                              o
_                  oO)m,                                                                                     oeleloe                                                                   lorelei
              _       e_j
                                                                  $




                                                         ..or..,)
                                                                                                                                                          '
                                                         m     â€¢                                                               r                 _T                I+
                                u4_        u-       :_




                                                   u_
                                                         _K   N



                                                                               ==" +.o                                                           |                     '




          _'_, _     0Â¢     ..,I a,-Â¢ _"    _-i     0"




                                     t i++                                                                       ._1                                   _                                  t
                                                                         ORIGiN_
                                                                         OF PO0    QUALI3_




                                       J3_




       ,o              ,.

       ,_              b,q

                               o         o
                               o         o


r_c3


                               Â°Â° 2
..r,   0        Z      m.
I..-   _        C3
m.i    Z        .,.I   Q




qi     I,_ ..._        Q
                                        iua
            i




                               I,-       O




                                             ,ii   u_
                               _c
                                             Z

                               r,,..         am

_..   eZ                                                    0   0   O0   O0
_.uOm                      â€¢                            0
                                                            _gdgSgd_d
                                             z
                                             ql
 ,.11 _l.I )11 _1




                                                        Z
                                                                                                                    V                  v      v           v                       i   V   _              v            v




                                                                                                                                                   _/_/.-, _           _ ..




                                                                                                                                                                   i

                                                                                                                                                                                                       lu.t

                                                                                            ..,.           _                    _kMkk      kMkkl
                                                                                                                                                                                                                       Ii
                                                                                                                                                                                                                      MJ
                                                                                                                                                                                                                               I   I
                                                                                                                                                                                                                              L,M _J
                                                                                                                                                                                                       " I/_1,11,
,i,. .I,.   .I,,   ,4,.   +   ,6      4,.   4,     4                               _0_                     4r)       '11
                                                                                                                       *Â¸       _f_"       _D_D                                                        ; I/I ,Ik

                                                                                                                                                                                                          0Â¢   G,,A
                                                                                    eeeo_
                                                                                                                                                                                              <r



                                                                                                               5[           ,

                                                                                   ooo_Â¢                                                                                                      Z                        0      Â¢)   ,-I


                                                               ,...,               000_
                                                                                   0000Â¢                                                                                                      a,m
                                                                                   OOO_Â¢                                                                                                       Z                       00Â¢)
                                                                                    eeeo                                                                                                                                9   â€¢        *

                                                                                                â€¢                                                                                             5r'




                                                                                   _NN                                                                                                                         2
                                                                                            â€¢         Ik
                                            tJ'_ I..(,                                              _4
                                                                                            ._      '.r
                                            ,--    ,91 .>      Z       ""

                                                                                            )--     O                                               Q                                         0

                                      ,,, ---_                                              C_       *
                                                                                                                                                    Q                                         g
                                      U.I   ,..I   Â¢                                                O                                               0
                                                                                                    .4"                                                       _0          eeeee
                                      41 *-*       q.
                                      1   Im             4"            I,--Q

                                      u.    l,_l,                                                                                                   _J
                                      ,.I   t'_ I.ij                                                Z                                               .,m
                                                                                                    _d

                                                         +     0               2                    O                                               0                                          0                          N   _J   r,_
            ,.,I
                                                                                                                                   i
                              LU      ,q    IJ     uJ    +     ey
                                                                                                                                   i
                                                         ,4.   u..                                                                                  u_

                              Lq_J
                                                   I-                                               J_
                              ..._    I,_   u-     v                                                U.                                                                                         u_
                                                         +             _
     g                                                                                              Z_
                              _.._                                                                                                                                                             Z

                              I,-0_                                                                 m                                                                                          t,,,e
                                                                                                           '                           i
                                                                                                                                                                                               ..0q
     Q       -.
                                                                                                    Z.

                                                                                                    Z                                                                                                                     O"_c
                                                                                                    _L                                                                                         4t                         p.. _    p..
6,4,4,                                                                                              _L
                                                                                                    I--

                                                                                                    ILl                                                                                        tt_
                                                                                                                                                                                               Z

                                                                                                    k--


                                                                                                                    - _97-
                                                                                  _4
                                                                                 p,.
ORIGi                                                                         ,,_m
                                                                                                           000000000000000000Â¢}

OF P( )OR QUA_ ITY

                                                                              i_      ,INI




                                                                                      ,4"
                                                                                      (P

                                                                                          oÂ¸




                                                                                      O
                                                                              I_      i,,q




                                                                                      r-.

                                                                              NO




                                                                                      N

                                                                              ,,.wlâ€¢



                                                                                                 O
                                                                                      O',
                                                                                                 ;.J
                                                                              O_


                                         O                                                       O
                                         Q                                                       N

                                         O
                                         O'O                                  Â¢pP.,              N
                                                 N                                                                                                    tJ_
                                         â€¢       ,,0                                             ,.n                                                  I.M
                                                                                                 O                                                    Â¢L
                q

                                         _0
                                                                                                 tu



                                         I_' It
                                         u_
                                         O,m                                                     J
                                                                                                                                                      -p
                                                                         .,ll         I,,,.




                                                                              ,,_ ,4P            u_




                                                                                    f,..
                                                                                    O
                                                                                ,,,#.
                                                                                    e_




                              â€¢          ZQG




       .                                                  Z
                                                                I




                                                                                           o


           _,;                           ILlI'M â€¢



                                                          tlu                   Z_
           -J       .=I       _.   Â¢.J       _   IJ
                                                          .J
                                                                         cj     i,.    -,P-



                                                          _v             Â¢.     _         ,=.1




                          ,                           i
                                                                         .o
   d       _P                 e)                  d                 ,0                 â€¢               â€¢             4            â€¢   4   â€¢   â€¢   â€¢    â€¢    â€¢   â€¢   d   '   _1   _   u
        I        I




        I        I



 oleoâ€¢




Illll



  â€¢oooâ€¢




 I          II



  oâ€¢â€¢io




                 I


  â€¢oâ€¢â€¢o




                 I



  ooooe
                      0
                      0




                                  p
Z




                              w



                        ell   _,9



                        c.gua




0




                 _l_O         LL




            =_.J==_. :
       eG   >,   !_           el.     el




: e
 I:=




L--a



 Q,
                                          ORIGIN/ _!.:PAGE
                                          OF POC R QUAL|T




           Z
           0




           0
            uu




           Z



           0



           u_




r..)       _"
z
_[         ._

4




L




0          O




           _q
Q,
Q_




                     .:_        _Z
                           Â¢_
                           m




                                          !,
                           m




IL     ,




d              _
                                     0



                                Z_



 LU            I'_



                                     2'




                                             -20
ql   â€¢   ID   â€¢           9   ql_          w




                                                   pRIGINAL
                                               C,F POOR




                                NNN_C
                                O000G
                                 iliii                                IIIII




                                                                                                                                     ,IP




                                    IIII       !                                                           0   Â¢_ ,..*   m ,..*
                                                                                                           o   0 o       ...* e-4
                                                                                                           o0Â¢_00                           "L
                                                                      000_0
                                                                                                                                      Z
                                    oQoo_                             00400
                                                                                                                                      _e


                                                                                  Z



                                                                                      m
                                                                                                                                            ul


                                    _NN_




                                    ..!..1
                                                                                                                                            5"

                                                                                                                                      0
                                                                                                                                      0
                                                                                                                                      0




                                                              e.          d

                                                                                                                                      ilk




                                                                                                                                     , u_

                                                                                                                                       Z
                                                              _g
                                                                                                                                       N




              i++i
                                                                                      Â¢0'1   i_                                             Â¢J

                                                                                        ,,   _.d
                                                                                             In     Â¢1      ,0*   O** O_
                                                                                                                       * ,Oâ€¢ ,43*           =a
                                                                                      (/5    _,'t   14J     _r    t_ _J _lP m4               _JcU




1                 +
                  k,,,,
                                                                                      .et
                                                                                      oÂ¢
                                                                                      tin.



                                                                                      _'

                                                                                      I,-
                                                                                             Â¢_
                                                                                             tJ
                                                                                             4[
                                                                                                    t.I.




                                                                                                    2':
                                                                                                            f_




                                                                                                             _"
                                                                                                                  I_




                                                                                                                  O" 0
                                                                                                                       Pc. p,




                                                                                                                           _,
                                                                                                                                I_           r-,L_




                                                                                                                                                     Â¢2




                                                                   -ao2,
L

                                                                              ;
        Appendix       C


MODAL   CHARACTERISTICS

â€¢   Business        Aircraft

â€¢   Small    Body     Aircraft

â€¢   Narrow     Body    Aircraft




               -203-
                                                                         i



                                                            ORIGfl_AL PAGE
                                                            OF         POOR    (_UAL


                                                  +

                     bk4




                     )-
                     U3

                                         â€¢   |i




                                                  I


                                                  I
                                                  i
                                                  !i

        .I
                                         â€¢   =i
z!
         I

--=:._




w,




=_.tl                                             _'q'. Io ,,0_




=-I                         ',F-,I
",,-!
                                                           ,Z
                                                       i
                                                       1
bql                                                    i
             E

                                                       i




i            ,
                                                                 :Â°_
w,                    ._.
uml

                                     i                                    b-
                                     !
                                     1




                                                                          !_                  :2;
I.-(I                _.


o.           ,
                                                                          i_ _-I   "_   _1 .'r" '




        â€¢     :.Â°:
             _Â° â€¢
                                                                                                    I
                                                                                                    I
                                                                                                    I
                                                                                                    I




                                                            -204-
                                                                                           i
                                                     I


                                                     I
               |o:                                   I
                                                                                  _L_'_

                                                     i

                                                     i
                                                     I
                                                     I



                                  ! ,           ,I
                                               o!
                                                     !
                                                                                                    L
                                                                                                    y.,-
                                                     i                                              I
                                                                                                    I
                                                     i
                                                     i
                                                     I
oÂ°
r.--

Z

i-



                                                                                                    I



Â°..                  0




                     â€¢-_        Â¢i_-    _r _
!=             ._

                                                |
s_
                                  I



Z
                     o            i
                                  I
                                  I




               Â°


                                                         I   ".'-"

                                                                                    . ,.., I   â€¢ .i        ..--.

                           i                                                      ___i
                                                                                  _'_1         -"
                           i.                                    _   .."i,"   _

       "-" Z                                                                      _ ..'..,
                                                                                       I ,.....
                                                                                          '_          I



                           I




                                               -209-
                                                            ORlelNAL    P_E        i_
                                                            OF   )OOR   QL[ALIT_




                               i



                                                                                        m




 LL
 b.


                                                i




_J                       ,+.               + t â€¢ '.-'-"

                                           _r       "_




                                   _: +"+I '
I--I
             -   I
                           mini            .t_.- m

Z                          _ _1            + I_ ..'.--.'1
                           _       _.4 t   _ul_      _._




             ii::!
,-..                       o.g i o,._




.j     _P-



                     I
                                      'i
                     i




                                           -206-
                                                              I




                                                      +!oo
Z
                                                      i

                  r_

                  o




        LZ
Z                 _,e!+
                  .i- â€¢ i-s'-':


w_




,-.,,




                  .'P   ._,=.i Li._=i
Z



                   ,                    e
                                        k    Zl




             V_
                                        +



                                        .."
                                              Â°   I



                                          ...: ;_.!
                                                      'i+iZ   Iv"   !




                  -207-
                    L                                I
                                                                                             i
                    I                                                                        i

                                                                               +   +   +_+

                                                   OF pOOR
                                                                                         I




               l--It

               i-"


                            ,'3




                                  t,',,,t

                                                                                                        p,,=,




Z

                                                                                                        "'_ i




                                                                                                        Oi



_!             "" +
                            .,-,_,,,,_+
                                            4- .I_
                                              ..'_
                                                i_

                            L'.+ I "




                                                     I
                                                  mira"
r-I            _t       '
                                             4, C41-"-"-"
                            â€¢'-" -"_1_      .,,,,4.'
                                            ,.,.i _     Ã·
                                                  ,.,_i,,,-i          b_
"'1       I _I+"
                            !_"::
                               @I "
                                              ,          ,-+.     !..-..,
                                                                  =.




3
      i <=t _i
        _I ':"'+                                                                                 _   !.r.
                                                                                                     i_._       :.
     =1_
Â¢ ,= .,T.I_
Z Z Zll.,t.i                                                    _:_        _




                                                   -208-
                   w                                              OF. IO00_   Q_ALi_TY



                   E
                   E                                                                 i


                                 rg
                                                                               i




                   _c
                        I_                     _=_+
                             Ã·    ,- L.i.i     +   ,_

L__


.......-                              â€¢": _.._ ,_


                        J




                                                            g::

                                  , C._        _"   ,C.I




                   _ i _                                    *
                                                            k_




           Â°   ,                         iu-




                                                    -209-
            ORIGfl_AL    F,;?_C_ o_._
            OF POOR      QUALITY




 MERLIN    IUC
     15      6
     i0
      5      3
50.0
9.27           0.84
4.54           13.66
TAPE    7 SYMMETRIC     MODES
TAPE    8 ANTISYMMETRIC       MODES




  SMALL    DIAMETER    NO.   1
      15      6
      i0
       5      3
 62.6
 13.0           1.145
 5.34           19.68
 TAPE    7 SYMMETRIC     MODES
 TAPE    8 ANTISYMMETRIC       MODES




  NARROW    BODY
      15      &
      I0
       5      3
 73.7
 23.0           i. 875
 6.73           23.64
 TAPE    7 SYMMETRIC     MODES
 TAPE    8 ANTISYMMETRIC       MODES




                        -210-
                              OF POGR _tj,&   L['i"




              _6

              Ilr'_
       I_      mN




              Â¢3_Z

                      III


                               I
                      iiiii




              Z

              Lul




q-,




.I-+   _z_r
 9:+
               OIZ
 CO
 o_


*Pt    I=
 o_




                                                      L
                                                                                                                           L              I
               010         QIQO              0   OtO      OICD       Q
      ;   _o   o,oo,oo_:o_oo,oo,oo,oo,oo_oo_:o,oo_oo_o,oo_o                                                                                   ooo_:o
           ..:_. _------
               "'" "'" "L*.
               4kl lilkl   l_   ;I-u . . .,...,..,.
                                       kkl                  . â€¢ :.=:
                                                 4kl *4kl kkl likl   M.I _k_ I&ll   LU 144 ILU
                                                                                                      .
                                                                                                 I_kl I_14i4   _MA I&l _
                                                                                                                               oo ooop:....,
                                                                                                                                M4.i_kl
                                                                                                                                         oo!_ Ud I.kl   t,kl u-_   .oo.
                                                                                                                                                                   I&l LU 4LI




                                                                                                                                              mo_r_mO0                          I'_




I0

I,.


El
IN
),.
V_

e'
la
91
                                                                                                                                                                                                                       I
                                                                                                                                                                                                                       I




                                                                                                                                                                                                                                                     li C'



                                                                                                                                                                                                                                  O_L:_i â€¢
                                                                                                                                                                                        OF iPOiR




                                                                                                                                                                                                                                                                                                                       i
                                                                                                                                                                                                                       1
                        _T+!+_+
                        -*,     ,+, ,,, *i, +++++-
                                            ,, ,,, ,+,,,, +-,', , t +i+_+++.+-++++-++++++
                                                                                OIOOIOOIOOOO_OOMDCD'O
                                                                       ,,, ol, ,,, o:, , , , ,,* ,,* , ,
                                                                                                                                                                                                OCDOO                                                        OOOOO                       OtOOuOO_                 O_           ':




             +Â°'!i!!!!i+
              ++    i                                                            It        !        tt       â€¢    â€¢        â€¢        I+        t    tl       I    â€¢        â€¢

                                                                                                                                                                                                +F++++++
                                                                                                                                                                                                    Ol

                                                                                                                                                                                                      ++"    â€¢       4)11   I.e       o.o       l+      â€¢    o,   i   i.    I   t+   â€¢    411+11    1   i

                                                                                                                                                                                                                                                                                                            .Â°++
                                                                                                                                                                                                                                                                                                            iit    â€¢       â€¢




                                                                                 li        I Iiii_41                  |_            I+        I    I,       I    *l*               I+       I       I*       i       lib    I*    I   I'    I   I+I          â€¢    â€¢    I,   I   II   I    I+   I    â€¢   â€¢   l*l




      ,.- ..,,           ._..,....._                                        ....                   _.','. _.I_. ".12 ......                                                        .,..,.


      _,_    91,1        â€¢        â€¢    e*       â€¢     Oo â€¢         O I â€¢         e*        â€¢        O*       â€¢    â€¢ `1 â€¢             e.       â€¢     el      â€¢       OI    â€¢        O*       â€¢       Oi       â€¢

      411 Â¢_?           lm N_         _r _D         lPllmlr       m       NI_ _l._Ir               _iP+<P        Ills ,m           _Olm           ll_*qP        m       _=I       m     _       _        _




                    , ._ +..+ +_o,..,...,.++o. o; .+..!.
                          .........         ,             I
                                                                                 â€¢'"  _|
                                                                                                          I"'                             ! "?'                         I               I


             â€¢+' o_ +,+ .+,* .._ .-,.+~,+ ...++"
                                               ._:_+_=+"
                                                      * _.-..,= .-.-

                                                                                                                                                                 ,|               ,;                ,I,
      ; =)

                              _            i            I                                               n                                 !         '
                        I_            IPIII_        I_i1_i        ID_           _If41              4_II_         14bll _           Oi_            'dP.fl i_     _hlqlP            *IPImlP       _Oal_

                                                                                                   ,4,,Ik-

                                      â€¢ O III_      l_s * ...*


                                        Â° I â€¢         â€¢       â€¢
                                                                      I lo iâ€¢    ol + +              ii, i   â€¢     â€¢ I â€¢             qli! â€¢         Ol      â€¢


                                                                  _-_IP         'rl"J_             It'tZ' I_|_                     I.,., 'r       i'll...       _II..             _t'J_         tt.,_s,"




imp




U



k.,
Iol
      I"'"
      I,.,
      led     Â¢_
                        -!
                        ,-*
                                            I             I"
                                                                      â€¢     â€¢    ot            â€¢     ot      â€¢     o_          â€¢     el       â€¢      ot     â€¢       â€¢         â€¢       oo    â€¢       el           â€¢
           9_ _
o._
ot: poo_




              +
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            I

                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    I
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    I                       i
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            I .                                                             â€¢i                                                                                                                                                          "_
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    I                        ,                                                                                                                                                                                i                                             '

            !




                                                                                                                                                                                                                                                                                                                                                                       i
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             i
            i

            I                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           i




                                                                                                                                                                                                                                                                                                                                                                                                                                      I         tl              I       _1                 I                 I             I            !1         Iil                      I         II             I      !1            III                    I II                 I            II                   IiI                      Iil                          I         _1          I                   I
ill                      iI                         li                        ilUJ                  ii                      liu._                lilll                                          Ill                           lllll                                               llil                                           Luli                                      ti                                            ill                                  Ill                                       i                Ill                     L'Ul                     II                    II                   li                       lilli                                                                   i        II                        li                       i             i
"l_t                      Nâ€¢                        #lO                       tit                   tl                      Nil                  II                       O__                   ,"il                          l!            t               O!                    _*t                   P_i_i                    O_                     iltlt                                                 __                    i_                        tt                          Oil                            It                      tt                       #           _         _           t        I            #           tl                     _             t                I                 _-I      i               _         I              I         _

                                                                  '                                                                 '                                                                                                                                                                                                                                                         ,                                     ill                       i.l_                        Ill                            I_;.ll                  i_l_                     mlON<=                                      .ll' ll_                l_ll                                 iltlt                              _l       i               li't      i'q            i_        _

                                                                                                                                                                                                                                                                                                                                                                                                                                       eli                       el*                        â€¢t                  â€¢           â€¢l*                         e_â€¢                â€¢(â€¢                     â€¢.â€¢                 â€¢_*                      â€¢iâ€¢                   â€¢,*                            â€¢,â€¢                             â€¢1â€¢                   â€¢,*                       â€¢                  .
                                                                                                                                                                                                                                                                                                                                                                                                                                    .i.l.e                    .,l_                        i_t,i,                         ll_,i_.lll                              m        km                    .ll,.                 km                      kl.i.                  k_4.                           m m_                           <lli_                 roll                     .i.._.

                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    t                                   I                        i                    I                     _                     i                      /                         i                                                           /                        _
III                      I_                         kl_                       _l_.k                                         _I           ltt       il                                           Ilk                           #il                           tl            kl                            IN                                  _                                                                            W                                                                    Itilt
Ill                      l!                         _t                        kl_k                                                P II   _ll tqP -,4r lil_                                      *ill                          I_l ll_l                      i        mill _41_"                         O I1_                    i          IPl             flil_i                      _         411__l                 _          t_                        m t                         I    I                         it                      kt                       _ll_                                        It                      fill                                                  mk                             il                    N              I         i_
    â€¢ ,â€¢                    â€¢_*                        â€¢              â€¢          â€¢iâ€¢                       â€¢        â€¢            "     â€¢    â€¢i  â€¢     â€¢tâ€¢                                          â€¢.*                          â€¢tâ€¢                              â€¢i,D        â€¢i*                          ot*                         â€¢iâ€¢                      â€¢l*                          â€¢*â€¢                    â€¢iâ€¢                     â€¢,o                 â€¢i,m,                        â€¢     â€¢                           ,,o                       *,*                 â€¢t*                      o,o                    â€¢,â€¢                  â€¢i,                     o_â€¢                         â€¢,o                                *t*                       *'*               â€¢                   "


,                                   l                             l           I1                                _                   _                                              tNI                                        MeN                                       |1        g_m*                              ,9,,I                   i                              _                      !           ml                                 II                      i                                                              _                        _,Imt                          i_tmlt,_l!                                    m_-_m                                                                   _mNiwi._



lilt!                                               ill                       N           _          _Wl##                                       ill                      II                    I_                            N             N               #i                    ti                    II                                              "                                                                 m                                                                                                                                      ,                                                                ,

ill                      _i_i                       i_ik                           ill I i                                  O,M                   li!N                    @_                    N)_ml   _lik         @_ll        (Ill                                                                   @_k                      N          !               lilll                                             Ill                    lii                                 I                k             I    Wl                                  i               MN       li                    i_ .I                 i      i                _      i i     i                                      IIi                            N      P               i'_
  â€¢    â€¢                    â€¢iâ€¢                         elâ€¢                    â€¢    â€¢    elâ€¢                                  â€¢   â€¢                OlO                       _iâ€¢                  Ol â€¢     â€¢     â€¢      0(e         el0                                                                   01e.                     elâ€¢                        0iâ€¢                         elâ€¢                   elâ€¢                    â€¢_o                       â€¢Ill                       â€¢              â€¢    I'lo                                  el*                    â€¢iâ€¢                  â€¢,â€¢                    o,e                    â€¢!ll     e*â€¢                                           ltil_                          â€¢|â€¢                   ll,â€¢                   â€¢
re,in                    (I.l_                      li_                       m_      _ti                                   ki_k_                                         ti                    OIl_   Iriitm        ,li"       tll_<r                                                                  m_ll.                    ml,l"                      _l.ilh                      l_l_ll_lt_                                   lt_                      irliN                       Ih            ,_   .illâ€¢                                  #'-i,e'               ki,              l"   i_t                   I'..l_                  0' )O I.O                                             â€¢ill                           _._ Im                 .t" <l                  m_
Iml_l_l                  ml,l"                      Imll                      N#ll     ml_                                  I_l i_                mMm                     t_ilN,                inllml m      lll._r       Mltl Illlmt                                                                  i_ll_l)                  l_lml                      i_l_N                       Nll_.,,.*ll_l                                Iml,_i                   m_l                         l_l           N    m_l'                                   m lml                 .t'l_                 <l._r                 .IP ;in                 .I. m'l .r     _l                                     i_l _1"                        .t     i_l             i_in                    m

;I                                                                I                      t                                                                   I                     /                      /                                 *_                                                                                                                                                                                                   i                                                                                      ',                                                                  :                     I                                                 ;                                 _                         !
Ill                      li                         ill                       k_                     ml         Ott                               I_                      l!                    Ol                             I!                            l_'ltt                                     ll!l                     O!'ll                                               litl                     I!                     l!i                      I              t            _             t                II                         ill                   I           _         1:1                       lm                  _i                     N              _               li                             _!                     k             N         _                 V
      ill                     *i.I                            eli              iI.â€¢                   iI+l-â€¢l.i                                     â€¢tt                         el*              II                   I               ill                      ill                     I.â€¢                 eli                    ill                            â€¢                 â€¢    â€¢1                         elâ€¢eli                                           *             â€¢             #,i                            â€¢iâ€¢                     ti             â€¢         ell               tie                       â€¢i        I            tie                       t              â€¢                   â€¢iâ€¢                      itâ€¢                      i.I                   â€¢


_i_P                     lllllr                     ,i'.14r                   _*I<P                  .4" mi                              _O.II_               O           ,4rlo_                olin                          ,,Irlt                         t_llll               41          #:tlt_                             till                       O               lil_                  4ill.                              ill                      Â¢ll.lr                      _1" II                         _l'lO                _ t_ll                                            _-ik                  ill                     I#                     lil_                           I_lID                                       _.O                     i_.       Ic;




 lit                     i_                          klk                      Otto                   ilk                    _,,,tik               tlI                     t.i                   _,,.i_                         I_'_                          k_u                  _ll                    Ntt                     I_                         tii                         N_                    tl                     '_l          _            t             i             ili                                           t                        i       NMi                    ""                                                      â€¢                          '               I                               I                                                               t

 _,1                     li                          Ilk                      nil                    lit                    Iit                   i              I         klsill               I         iN                   Itl                          'I          I          ill                   II                      t)                         ill                         t         _            N           _         kM                        l,_                         I                I            Ill                        i            I        I           __         l          le            (:i                 t            tiT       *iT t                              i             W             )           _         _             i         _                 ,_.
 N!N                     i_N                         Nilll                    lIWNli_                                       Nlli_                 li'llml,lmllll k      N                                                       i_i k                            ilml              iill                  Nllll                   i_i_ml N     ill N_N                                                          Ipil                  NIl                      i_i                          "IN                           _,ll   N                                 N        i_                    k_                       li!N                i_i                     _i                                N_                          m_'i                  i             i         _'_-
 :Jr'â€¢                    tie                         â€¢ll                       â€¢It                        el.I              eli                    â€¢  â€¢-  eli     â€¢l.â€¢                                                          elâ€¢                              ill               eli                   â€¢1â€¢                     â€¢1â€¢     eli      BIB                                                          O|e                   Of*                       Oie                         OIO                            I  â€¢   â€¢                                   l     â€¢               â€¢     OiO                      itâ€¢                 â€¢1                â€¢     tit                               â€¢i                          itâ€¢                          â€¢;*               *'

 'i'                            sli'l                                                    /               ,t,                            I                    I                     Vi                     i                       ,!                             ,t                          J,                     I                       /                               I,,i'/'                                                              I                       !                              i,                              I*                       I                    I*,;                                        I                        i                        i                                 :                                           "                                 '

 I                                  Lt                                                                              /i                                       I 11                                                                                                       I                                           I t                                                                     /tl                                                                          //;.                                                                                    I /I                                                             t /l                                                                                                          b                                                   :
 Ill                     I              I            _.,tlt                    11Â¢_                   IIm                   _           li         m Ik                    l     It              l*m                            ll',C-I                                     _,_    Ilk                   t           il_             ill                    llwl                        Ill                    k           t_         i     t                  t             IO            _ i*                           I ll_                     I            _         _ F_                  i   ,i                    lli                 N           !t         i   _                             i     l_                    _        I                k     k              I                    c
 I              IIp                                  k      t                  lit                    k   k                 kl                     k  i                    k_                    ilk                            t       ll_tl                                      /|I                   _            k              t!                     /       m                   II'IP                                         t_t.t                                   I_           I_ i_                          I_lkt_i                                          ki_                   k#                       It                   II                     l_D                               I!k                         _        _                tk_'"
       oie                     "t*                            el*                       *f*                el.*'                  *+*                      el*               el*                    eli                            *i*                               llle             el*                        â€¢t-e                   it*                   i,..*                       *le                      ell                  â€¢t*                         *1          â€¢            â€¢1*                           e.â€¢                              eli              I.tâ€¢                  â€¢    â€¢                     eti                    eli                â€¢   *                             eli                             *I'D                  o,le-                   â€¢,

 ,t              i                                            I                     i    l       li    tl                                                    I                          l                 .!                                        I                                  I if                             1                       I                           ,i              li ltl                              .                 '                               .                     I'                              /.i                      1              Ill                         Ii              i     I                I                         lii                                      il                 â€¢it,_                              .                       ,
 0.1.._,..to..                                                                                =..to. =,,Â®o.,. o._, it.-.                                                                                                                    Â© o_ - ,-ll_                                                                             -l_, -.,o*.,*. -l-;. o_-.ilo. it*. o,i o..t.tl_ iio i,o. oi- o=.                                                                                                                                                                                                                                                                                                                      o o = i .- Â¢,_<
                                                                                                                                                                                                                                                                                                                                                                            lilt                                                      _                        i_l                         iI                             _                                                Im                    llilm.ll                         I            I=i                    _,.4 id                                          I            i                         _i            _                       .




                L'                                                                                                  I I "F,                                                                                                                                             L                                                                   I.,'LilL                                                                                                                                                                                                              :b
 OilitOOtOOtiOli                                                                                                             OlOOiIO                                                             iOiOltiOOOiOOOOiOOO.tOOiillilÂ¢_OOllliÂ¢:lOIOOiQO!oi_iO!oO_                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    O_                   O                    Â¢




 .I L I I L 'ILitLi-                                  ,,.*,-_.-                 "_            =,,* i                W       I,,.*                                                                                                 ztrr                                              f             k*i                   2Â£           _*                      i                  2_ 2T_=*          i_Lt/t                              I"              i           T              2[         2[               2_               ill                       r        t;;i      _.*                       i,-*       Im        lliZ                 w             t  Z     i.,*              li,*                i          L                i,*       li-*        I-I           :         T*.


    _.'s,_i_i_;_i_z._'_z.iP_i'.i'._i_.i''i-_i_ii'._i.'_i'i'_ii'(_i'i_i'.'_i_i_i_i_i__i_iii_                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           _:




      t!             â€¢         II               â€¢                 I I â€¢           el            *              .l       â€¢      el   â€¢                    el           *           *1        t          el                 â€¢             t !             â€¢            o t â€¢                   oI     â€¢         it             â€¢             *t       â€¢               II              â€¢        II           â€¢       *I            â€¢           â€¢t            â€¢          o|               â€¢             â€¢                â€¢              el          â€¢                 â€¢ â€¢          I    â€¢                   â€¢   â€¢                t            â€¢                  I â€¢                 â€¢1             â€¢                      I â€¢               â€¢  â€¢                       I       i t          t i
    kiP_                  I                 _         tit                       _t#                      #          t        I_   _                    _ll                  i       !               ilk                           Ill                            i      ,li            ill                   _1#                     ill                         Ilk                        _,*lt               _t#                       IIO                     lllIi                                      _                _              IilO                             _*),_                  ,=lt_m                 Ni_                   lit                    i              I_                  ltt                         O _                   t             O         ,,,,.*,<



    Ill                   i                 i             i           I         i             l,_        _          i        i               I         i          _         _i                      Ill                           i             i                All                _i                       i          Hi                      I                ltl                        _1_                 _                         li_             i       #I#                       .i                   i            il_,i                     #i                    l_                     _#                   Ill                     itll                                  !                   _,.i_,_                     ,_l_                  *,i           â€¢i        .,.,i,.
                m                                                                         !                                              I                    I                                               '                                                                                                                                                              ;                        I                                           '                                                                                                               '                                             /                                                                                                /

    i_li_                     iTI           i_            ll,,i       li,,i         Illi,,i              _          i        i    i                        lii              ill               I                   i               i             k                k  t_                 _ik                   i_,l_                    k   _                      _!l                        ill                    Itl                    ill                       lil                         I                I            tt_                       # !1                  # I_                   ill                    #tO                   OIO                    ilO                                I_ll        O _                                   O             =,,,,* ,,,_,.
    N     _i                  N             N             _           N             NIN                  _          N        NIft                          Ni_              N           ei-_IN                                    N             el               N_                    N   N                 _iN                      C_J N                      Ni_                        _let                   WIN                    Nl_i                      NI_                         N                _i           Nli_l                     Nt_                   N_                     NI_                    Nll'_                 _ll'_                  _q'Bi_'t                            L'_'l!i'_i L'_'!_                                m             _




                                                                      I                                                                                          tl 'ill                                                                                                                                                                                                        CLLIL
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  lii lti
                II                                        II                                  _                                   .                                   â€¢                                   â€¢                                             Ii                               _                                   _                                         _                                  t,.                               i                                     i                                                 b                             i                                  i                                t                                  &                                                 â€¢
-.p
                                                                                                                                                                                      :   ORIC
                                                                                                                                                                                          OF     'OOR       QUA




i=l Ill   ll_     dl   il_   li_l   li'l         ll_       *i_ill_   ll% M'l    Si'_ili_   lIPiili=s     _        ii_ ili'slil_,        i_ili_        Si_            ll_lll'l


 l It    I        il          l_l     Ill                             I_I       _'I??:? ? ? ?',??:??_
.lli kM i_        MJ sIJ LU Ill IS/J _ilhi.l                         _ ii_                                                                                           u-a ;LM
                                                                                4D*ed      ..,41Â¢_       '0t,,0         .IPl_"          _,Â¢%1S'_D
n     R   .,0 I_       0" Â¢'_I qli4D                       li_ tS'Pl .=.OWP_t                                                                                        Ob_l_ ,


                                                           ,..oio op-           alia)      ,,Otm         I_IO           ,ill,..0


            â€¢to

                                                                                q_diJ_P' CP 0            lit      CI_ li,O

                                                                                ..lilil    Â¢PI_          I_l      ..*   mill            *ted          *it*

 o_o        _,9                                                â€¢                                                                                                              o
                                                                                      p
                                                                                      t
                                                                                *diliP      _Oitll             ill                      IBli'l         I_l_,lt
                                                                                Â¢l.ii      lilll   I_ ,,.llll,*         liP"            IOi=P         Illtl



o uP F,., ,0           ,_    _0      _.,0                                       .llJ ,41_ --*"_....
                                                                                              is_l tl* !l_l                                                          _        tP,,,


''                                               i                                                                                                                            i
                                                                                Â¢DIP'.,    O_tf     ".   ID       _     I.i        Ii

olo         â€¢Io          â€¢      â€¢          4)t         â€¢                                                                                  tl_     â€¢      o_      â€¢       o*       â€¢
                                                                                                         _,_,0
                                                                                                            lip,,,,
                                                                                Â¢'_tCt     Â¢PtiD

      '                      _i .=,_


p pt ,,,iPO, m Â¢_ _.*_wl Oitl_ _t#,l,
                                                           â€¢.,*_l    ,..,_

                                                                                ]!;;i2
                                                                                .*let      l_l I Â¢I
                                                                                                                        it]l,           _l!m
                                                                                                                                                I"_


                                                                                                                                                      m
                                                                                                                                                             /       '='_


                                                                                                                                                                     iPiel




                                                                                                                                                                                                    I
                                                                                                                                                                                                    CLLIL

                                                                                                                                                                                                                  â€¢   â€¢   â€¢   â€¢   â€¢   â€¢   O.
                                                                            0 {IGINA
                                                                            o! Pool  !
                                                                                 l
                                                                                     I
                                                                                     I

                                                                                     !




                          Â¢=,m                                                                                             â€¢ !
                          z:                                              rtO00                 DO
                          ida
                          Vii


                   _      im ires




                          Zp.!                   ,-*   I0.   ir_   ,o0,
                                                                             000                =lO



                                       i




                           I&lq

                           Â¢:1_,
                                                       L
    Coo                                                                   _el_           0      ID    (=




                                      i Ii
     Â¢d
                                 m
                                 l[
    Â¢.1            I1_     i.,* im
                   if.     M,.I



                   tf,_    Viii

                   _dS C2Â¢
                   _1,- 012




                                      io!IIIEIEIEIil
    0

              ,4           0
    r-t
                                                                                         Â¢_10         Â¢    _0100
              C

                                           ,                           o, â€¢ o C_ oio
                                               _,,o*o o*,, oo_/p o*Â¢_oto
                                                                  el â€¢            *4. Â¢:_
    u=




                                                                                                           Â°Â°iÂ°
                                                                                                            i
              -1



              0
               Z




          I
E                                                                                                             _v   v   v
                                                                                      ]      I
                                                                   â€¢ ram+At,P+
                                                                   OF. PC'OR Qt IALI"r_,,
                                                                                      t

                                                                                             t
                                                                                             I


                          !+i'"
                                     Do      _0000                  010        OlOOIO0                       00;

                                     lllll    i_ u,l,IIu.-' W,ll*.W 1,1,1141,1
                                                                            W++*,,,l4_,u.+           ll_i_
                                     O0      + _+N          _10     _el_    NtO     +10              _10           +t


                                             â€¢ ,4' + O1_'_          ,,â€¢l,,â€¢ ++t_'_ + I_          .â€¢      i_        ,,,_
                                              â€¢ o( â€¢  0+*             *t * â€¢+ *     ***               ell             *I
                                     u_

                                wo
                          I t1+11_ 0
                          p IDI p a,*
                          D O+D g'*                       Ot_*O                O*m        Â¢_10   0
                          DOtDO

                                                          o,oo             _ 0. o or; +" _I
                                                                           ,,_, _i_       o, imo,,           ,,_ o, i
                          ii4ml + ii_l                    _   +iiii q_l,

                          Ir P,,, ll_      I_ loll,    0" I..,_ ._                                  I, oi,|
                          illl    ii ii,ii i, _4+i i_ i_i +llil ill        iil IM kml i_I )pl ,ip_l Jllml
                                                    I
                                                     I
                                             ,.* _11Ip                     k.0 T+qI" i_II'    _* IP_*l
                          i.      I[ i, E        l_,I'-   frail"    II     _i, _r'_z fail s'' I_lr  l-,,l
                          â€¢       _DI â€¢ 2"                 ZI)'-    Z

                                                     I
                                     410     3" ID __I' ,q011k,, m


                          I
                              i     â€¢ â€¢ â€¢ â€¢
                                  Ik, k,O   _ ,â€¢
                                                 11

                                      â€¢ Ii_ I_ iP+,
                                                            i| â€¢ â€¢
                                                          ,o llm,,+_*
                                                          iI_iII'_ ,,o
                                                                                                             ...,"-.,
                                                                                                             IIDI

                          4* 4'      9,_,,   41" qâ€¢+,â€¢    ,Ol*Ir    â€¢"                                   I

                          Im Â¢PIIR ,,01 m- IDCP           O|+',l    N




              I
         i-

i_   â€¢   â€¢        â€¢   â€¢
                                                                                                                               i

                                                                                                                               i

                                                                                                                               I




                                                                                                                               i

                                                                                                                                  J

                                                                             )RIGIN_L                                              PA_-Z                            ._

                                                                             )F POOR _U_LI"                                                                         If




                                                                                                                                                                                                                                                                                                                     '1                               ir




                                                                                                                                                                                                                           ooo                                                                             ooo_ooo_
                       ,,,,,,,                                                   _,::,_,:Z_._Z_, Â°'Â°Â°                                                                                        OlO         of*
                                                                                                                                                                                           l,i.l l_i_ l, li,l ill          IJi8 u.j              Ill                 144 I.M Lu                            LU Li.l             MJ               uJ     I.I.I IJJ                          u.l,l i.i,l       _




               ()      â€¢         â€¢       I)     â€¢       oil)           Ol            o        â€¢          â€¢        _io        o,        â€¢       el   i)     o_      â€¢        I)1o             Ol      I        olo              e)o                     e_o            Ole                 o(0                  t) LI             el       l)     I) jo                 Q[                     O_e               '
          J
                                                                                                                                   I                                                               F                                 i                       ;                                 i                     :                                 :                     I

                â€¢     â€¢   â€¢     gig    *IO       el*         *Io       *to        e*O       *'"                                                             Oil)             â€¢         â€¢     Ole               O|O               Oil'              eOO                   elO              OIO                  eli               olo       eli                         elll                   ote               ,
          ii   e Â¢1,,t0       _!_   _,,., !.11 _          m _N ...t.=,         .ero       m._r.._                                                              I           ,_,N            I_, _'_           p,- _         _        m             m _                m      _         _     _              o         I         _    e,,..o     m                   _          _.          _         L"_     _
               _O_OtmO_O_L_OIoo_DOIOC_;ON)OO__AmI_T_N_                                                                                                                                                                                                                                                               t         _-*_m_r__
               ,,,_ ,_ *,,.* ,,,* i ,_ l,,_          _,,_ ,.,* *,,,_ ,_ t,,,,* ,,,o l,,,_      _                                                                 i,,.*     ,,,_1                   _.*             |       ,'*       *'*                     I       _1               "o       _'_                   I         "_ _'_ "_ ,'"                                  t                     [




Mml             â€¢       â€¢        â€¢        Ore            Oje            â€¢            â€¢        Olll                010         O,e              â€¢    â€¢       O|O              Oil)             O|O             O_O                e!e                   O_e               OSO              o_o                  Oio               oil*            oeo                   en                     I_o




               I       O'.I_             NI_O           _*I_           milk-                 _I_                 m0I_        ,4.1.-* _'**Im                010         â€¢ _I"_,* OIO                          mI_            _' IN                  ,,D                        p"

=.,I
M.-i
           "
ulm
_) Â¢=I.




                                                                                                                                                                                                                                                                                                                                                                                                       -
                â€¢          Oil            II    I        Ill             II          I            Oil              Oil        It         *   *       *41'i           O      Of*                el     e        O_ O              â€¢           â€¢          It       I        â€¢       t        I        t          OI          I        tlO              OtO               Ol_                  ell

                                                               /       â€¢ 11
                                                                              t                       I',_
                                                                                                        e,l.=,l
                                                                                                                                   / ,1 .I"l
                                                                                                                                       .,=*m        I ,I.           ',t,..*     I
                                                                                                                                                                                                    I' /
                                                                                                                                                                                                     I                               '
                                                                                                                                                                                                                                         _ r' .                               I
                                                                                                                                                                                                                                                                                               t                      !   I
                                                                                                                                                                                                                                                                                                                                        /                  !,!     N              I        m
                                                                                                                                                                                                                                                                                                                                                                                              ,r            _




                                                               I. loll LI,                                                                                                                                          LL                                                        L.L.L.LoL
               IP      _I_'              _.I_"          _'l _          o' r_                 f_l,_" _I_"                     -",_              _._,m       g_'l'*           _u_             P,-l.o           _.             _,-,                       _o _..r _              _        _.,_                 _D                  _                ,4' _             o              _-       _- _

                   â€¢       â€¢         â€¢    â€¢         â€¢    â€¢         â€¢        el           â€¢        â€¢          â€¢     I     â€¢    â€¢            â€¢    â€¢      â€¢    â€¢          â€¢      â€¢        â€¢       â€¢         â€¢     â€¢       â€¢         â€¢           â€¢          â€¢        â€¢        â€¢       â€¢        â€¢           â€¢        ol         â€¢        â€¢       â€¢        el        â€¢        â€¢             â€¢        â€¢        â€¢
                ,,I,I I ,, l',ItI ,I,,I"I ,I,I ,I,,,,I,I:,!,I;, I I;
                               I.                              i                 I                                                                                                 I                                                     I                   I                                  I                     i                                    i

                                                                                 '                                      L :Io'IL                                                                                                                                              L'!L                                                                                                                     L
                    â€¢ "i*                     "1....                             I ............                                                                                    I*           "I" "1".....                                                                  /......                                                     }" "1""I" "1"
I_uJ
OL
                â€¢.1,-.I- ,-..-I..-I..,11,
                I_ I   s*. â€¢
                                       ........,.,,...I...
                               I-- T.. T
                                                        -.I. -L-.-
                                                                 I.--.--L- ----
                                                                       T    _r                T. _I_ _                   'Jr"'rlm"   m"II.                 _        I"      ,r. _  I,='Ii_ 'r'II: II.i_                                                Imp=.          I--_                _.*I_                _I" lli i--iI                     i--l-- II_I                                  t*--If-- I
                   _I_     _|2     _   _                               11"!>                  11"I)" _f                  _   _   11" )-t11,,               _        _       _ 11,, 21_     _t_    21 "_                                                _!_            _                   _1_                  _12     Z_                        2 _'_" _1 'g'                                _ _      :
rl,,-




                                                                                                                                                                                                                                                                                                   I
                                                                                                                                                                                                                                                                                                                     @
g-



                                                                                                                                       CIL_L                                                                                                                                                                                                                   0         I            _            _
                                                                                                                                                                                                                                                                                   ._!
                                                                                                                                                                                                                                 i
                                                                                                                                                                                                                                                          _P      ,oi:q J,:",,

                                                                                                                                                                                                                                                                       i
                                                                                                       i



                                                                                                                                                                                                                                                                       i
                                                                                                                                                                                                                                                                       l



                                                                      P



      tl
J U.I W
       I                li   i
                        148 u-,
                                         I   i II
                                        4kl _11_.l
                                                                 iti     i
                                                                Ud +;,U U,I
                                                                                          0
                                                                                          I
                                                                                                   _*00lO
                                                                                                                               I
                                                                                                                                       0
                                                                                                                                        I       +'+;+
                                                                                                                                                   +',
                                                                                                                                                    I+_'""
                                                                                                                                                I,I,I 41,11111                  Wllldl
                                                                                                                                                                                                                       I. II
                                                                                                                                                                                                                 14,1 I_IIIII
                                                                                                                                                                                                                              _,IO




_* hi          _1t4"              .-*'<P         _110           ,,O_D           d"        N
                                                                                          4
                                                                                                   p!qlp
                                                                                                  4J.-0
                                                                                                                    _ I I_
                                                                                                                    m lP,-
                                                                                                                                       lip
                                                                                                                                       ,4"       : _t.Â° ,.-,- ..._. -,o
lie             gig                â€¢       â€¢      Ole            o_O             O'           â€¢    mao               wig                  â€¢


                                                                                                                                                                                                                                     t

â€¢ )O                â€¢              â€¢  â€¢             Oi â€¢         Os        â€¢     el           â€¢    â€¢           â€¢     el            â€¢      â€¢ I â€¢               ol        â€¢        o_            â€¢           o|
                                  emO            e,,4 levi



':+   '                                                 ,       " LI  I                                                    i                    ['                 1




â€¢         â€¢         â€¢   i â€¢        â€¢       â€¢       el       â€¢    el        â€¢     â€¢            â€¢    â€¢           â€¢      ol           â€¢        â€¢       â€¢         ol        â€¢        ol            â€¢           â€¢




      t                 I                               I             i                   /                I               /                    I                  /                       t                     /
_11_           tt       |         I_    I,t      III     I.I.   pl        1_111_ itt              0.11_             ItI tllt             II_|    II         _Irlll_             |_                     I         N            e,,tO,,
â€¢ _- -_.                           â€¢ â€¢ *i..1-                                        -t*           -+-                .t.                   *1- *,*                                  -t.                   *t â€¢P ,,OIf_
                                                                                                                                                                                                                   _i,I â€¢



                                                                                                                                                                                                                      I_1


      /_".                                                      -i/I                                                       I /'rl                                                                                I
                                                                                                                                                                                                                      : _I_


                                                                                                                                                 I_
                                                                                                                                                    I
                                                                                                                                                     â€¢        ot



                                                                                                                                                            11'11,4'
                                                                                                                                                                        â€¢




                                                                                                                                                                                                   '              I
                                                                                                                                                                                                                      ,-,o
                                                                                                                                                                                                                      â€¢         el



                                                                                                                                                                                                                      l't II_I,,_IP
                                                                                                                                                                                                                                         â€¢




                                                                                                                                                                                                                  i

                                                                                                                                                 m          IDIII_              II_II0             " II_              i        411_I14_I


                                                                                                                                                                                 _t_ =i ++,,,,o                       I'_ II'I IIIPI
                                                                                                                                                        â€¢      II           â€¢         It           â€¢        o!        i          !1      !
                                                                                                                                                                                     III                   II

                                                                                                                                                                                                                      iii IM iI_i

                                                                                                                                                                    l
                                                                                                                                                    O"       I".tO               010                   _              D        0'*0


          i /"                                                                                                                                      0        _.*11 _"
                                                                                                                                                                       pl        _..li_l
                                                                                                                                                                                 _DI_P                     I0
                                                                                                                                                                                                                      m
                                                                                                                                                                                                                      _* i'..l_*
                                                                                                                                                                                                                                      p.I

=         m     _           r..    _       m      _i,r           ,-*_            o            o    _lm               m!*.-                ,-,




                                                                                                                                                                                           /
_,        i_    N           L      N       f      _         _    o,,_l_          _,_ ir            r           _-    7             _._              am        0-.tSL"            9"i*_                     _'*        N        k,i_-,


_         ;     I,.         I..    I.      s-'    IDts"          I_+'r           I,-


                                                                                                   _1 _lr            I_11_                _




                                                                                                                                                    +...;..:.
                                                                                                                                                         ,_i++.
                                                                                                                                                             ?-,,,+-                                                      â€¢      el          â€¢


0         0     ...*        I_     _J         ,4" .,,o1<=        I,,,,,,._O,,        _,            OICD               _.*t,_
                                                                                                                                                    +"+'+""" =,._I_
                                                                                                                                                              _Jl_l                  _Jll_                 _t,


_2_,o o-+,,,,+,+.,.
             ,,,

                                                                                                                                                                                                                                                     -; 23.                I
                                                                                                                                                                                                                                                                           Â¢_L_L


                                                                                                                                                                                                                                                 â€¢    â€¢       â€¢    â€¢               â€¢     â€¢   â€¢   â€¢   G
                                                    C IG_N_                        F
                                                    OI _00R                        G JA
                                                                       I
                                                                       I
                                                                       I
                                                                                                     k




                                                                   I
                                                                                                     I
                                                                                                     I
                       e_k
                       em
                       e-

                                    00'        in     ,_.1
                                          Nlm)_

                       OI

                mlA




                J_
                       II    =D
                       Â¢     Z
                             .=[                             _olmc                  OC                                   OC
                             ns

                             Z
                             me



                                                                                                     I
                                                                                                     I

                                                                                                     I

                             Z
                                                                                    _r1Â¢                      0Â¢         0Â¢   0
                             ,nn
                                              i                                                      I
                             Z                                             I
                _m           era*
                                                                           I

                                                                           t



                _L                                                         I
                ,vÂ¢                                                                                  I
                I--C         Z
                u'Jl         4I     *,-**f        0    w                                                      OC         0Â¢   0
'1::1   Z                    nn
 0
                             2
        I.-,.                Ii=
        .eL
        S"

0
        LL
                                    o.=.=.,
        Z       Z"                  0Â¢_0Â¢
        ==1     LMf

        =,_     O"
        "=[     Lt.
        Â¢2      l
        C       u,-
        Z.




                                                                                                 ,_24-
                                                                                                         i
                                                                                             CÂ£&_&

                                                               t               â€¢           _1.           k.        4.,        _.,   tL.   _..   _..   â€¢
                     V

        _OmQ_N

                 i
                                                                                                                                                                                 I
                                                                                                                                                                                 i


                                                                                                                                                                                 t
                 I




                                      3R
                                      )F PC 3_                          _LIAL


                                                                                                                                                                                                                                                  O0
                                                                                                                                     4_      ,I,      4,4.                 I*+,_                                                                  ,11. ,4*
                                                                                                                                     kll II+IWa       W.I I_I W,III+ W.I_ IW I.I,14                            ee_l       1,1_1t-u LLII LI_ I,_   UL+lt_

                                                                                                                                     .+                          m. mm+,                                                                          mm
                                                                                                                                                                                                                                                  _em
                                                                                                                                                                                                                                                  IPIm



                                                                                                                                                                                                  â€¢                                               _rP"
                                                                                                                                                                                                                                                  m_
                                                                                                                                                                                                                                                  _m


                                                                                                                             0                                                                                                                    OG




                                                                                                                                                                                                   "                  ""2"""
                                                                                                                                                                                                                                                   â€¢      q




                                                                                                                                     IP" ,i_                     II_l 0"   0DI ,,0        I_,.,                                                   mO
                                                                                                                                                                                                                                                  ml_m
                                                                                                                                     tulip       i1.1 p.I   llml ewI i,d   im_ lu.q i,m

                                                                                                                                     m,      _   .0   m     _    0,,t m    .TI       o_   g',-.
                                                                                                                                                                                                                                                  iml _lm

                                                                â€¢        â€¢              Ik
                                                                                                                                                                                                                                                  NZ

                                                                                                                                                                                                                                                  Z)"

i

+
                                                                                                                                                                                     I



                                                                                                                                     "
                                                                                                                                     Im,._
                                                                                                                                                                                                  I_0,000.__



                                                                                                                                                                                                         i
                                                                                                                                                                                                                      â€¢           â€¢       â€¢   â€¢   I_.ii

                                                                                                                                                                                                                                                  N_



                                                                                                                                                                                                                                                  0"Â¢
                                                                                                                                                                                                                                                  O'C
                                                                                                                                                                                                                                                  iI_!1




                                                                                                                                                                                                                              i




    t


                                                                        Q     010            04 Â¢_             0       Â¢3Â¢
                                      QQ       G, QOÂ¢                   O     010            Â¢_0Â¢                      0Â¢
                              Z                ._, WD ,,k ,I                                                           .41 ,4,
                              0       161 I,Id P,_ UW LW W
                                      edOD     _Oa
                              m                                                                                        p,,,Â¢
                                      mlllR                                                                            a_llP
                              L       mQ.
                                       â€¢      o,                        _,'_":"I ",Â°.,
                                      cell e.i.                                                                        lipII _
                                                                                                    1
                                                                                                                       +,mm
                              _G      Q_o
                                      0.4_                              _I_                  _Â¢
                              Â¢_
                              _q
                                                                                                                        â€¢        t
                                      0.-1

                                                                        q_     el       â€¢      â€¢         â€¢         ,

                                      i,.4

                                      0'.-0                                                                            wP_
                                      lie




                                      ZS_          sl-   zlI-       _
                              0_      Zml"
                              0_
                                      ISI_I                                                                            _v

                         0                                                          t
                         Â¢_           O_ I',.
                         i-   O.,-
                              w.,4_                      +I+.<             â€¢   qm â€¢             â€¢          â€¢
                                                                                                                       Q_

                                                                         0,+ _ul i_l          .d.       I,..   p
                         ml   LL.m    0"



                         g    _                    I
                                      e.lee
                         _    C2                                                                                       _m
     _o_amo




                                                                          i$




                                        .m                                                d.I I_l             I_1 _            I,tJ    1.1.1I
                                                                          ,0_




                                                                            eoeoeol
                                                                          !__1

                                        2_



                                If.l_
                                _.qll                                     iooeooel         â€¢         ol          â€¢      ol         â€¢    â€¢
                                                                           _mN_
                                I_11.
                                                                          __




                                m,0 _i
                                ml I_!                                                1   ,o       ,o le,,,           NIO              .0

                                II
                                                                                          ,G       ,,r        I.I,)   ._       m       -,0
                                uu..i
                                Z     qi_                                                  â€¢         .l*                .i.             â€¢

                                UI      0:




                                                                                          m        <1" I(_1           aD I,,,,I ,.,0
                                        I.
                                        Z:
                                Lu      r:




                                Ll.,              0




                                        Z


                                                                                            â€¢        of          â€¢      el         â€¢     â€¢
                                                                                           I                                            I
                                X

                                        _e




                                                                                                                               I
                                                                                          0"       ,,OIM".            I_I,_,




                                _qL
                                        41.




                                I_1 U,I
                                                                                                           1

                      0
                      t-
                                                                          ,O_N_O_

                                uu_                                                            â€¢         et       â€¢        â€¢       â€¢
                                                  m




                                                                                          2--0
                                                                                            j;
                      _         uJ



                      _         E




Ik     T      A   â€¢        m,                 _       â€¢   c   6._   /,_                            Q                           â€¢
ql,            â€¢           I                                 â€¢                       1t.               â€¢                                                     â€¢.   _   I   â€¢   O'   J)_   r   _   ll




                   f           _            m           _q_l no _i_
                                                                                 l:lOl
                                                                                    '


                                                                                 "I,4"!       II lad 0" ',_!
                                                                                                            _+:
                                                                                                                                                                                                      +++
                                                                                                                                                                                                      I,I     l,l,l


                                                                                 D _i
                                                                                 _0",
                                                                                              m. _w5 _
                                                                                                     0"_'_
                                                                                                           ew_
                                                                                                                                                                                                      ,_o_
                    â€¢    â€¢
                   g" ,,4'




                       â€¢           â€¢|
                                             â€¢     ol
                                            _l. f4il




                                                â€¢        o_
                                                                  â€¢     â€¢
                                                                  4,1 (_d




                                                                  â€¢         â€¢
                                                                                                                                                                                                      ::"
                                                                                                                                                                                                                      0'

                                                                                                                                                                                                      â€¢       P_" _w_




                   1,*0"l_m                                       o,,_           _<P'
                   :1, drY( 4" f_.l                               _p Â¢1          ;1',,4'


                                                                                                                                                                                                      _.- _.e,        _
                   ,iPe_ll,,,..                         _)        _,,,_          ..*eM


                                                                                                                                                                                                      _       ,,00"



                   _           *l'l p,O m)_                               ,G     O0"
                   D           (.7 lqD ,,â€¢I_-*                            _[_    O I_




                                                                                               â€¢       411 â€¢           4
                                                         i                       I                                                                                                                               I I

                   urll_                                _r_ll_l           ,,i    i'_I




                                                                                                  â€¢    ol       â€¢      i
                                                                                                                                                                                                          I
                       I                _                          I             I
                   lu          e* Oral                   JHm,I            m      _,,,i am


                                                                                                                                                                                                      00"Â¢1

                               "I
                                        (




                                                                                                               11_,4
                   Â¢1          _I_                       Â¢100              Â¢     Â¢1       Â¢                                                                                                           0Â¢10



                                        S
                                                                                              _       lr.l'r        T

                                                                                                                                                                                                       1,-1




                   CO,,,J, llv_                          0"I.,,â€¢            ,d   t_(                                       e,*   Â¢1i e,e    .._i 0"      ,

                           â€¢        ot              â€¢        el       â€¢              â€¢,

                   0"              OlO                   Â¢140              ,     *-*o         m4      _..4 _.4 e.
                   m               ,_1.0                 ,41,,0             ,     ,_  *
                                            l




                                            I



                                                                                                                           '_,ll '_l_ "_'   _'     "_I
                                   ll_lldl
                                        _ _lll _                            _    _                                         ,_    ',r.l.l_   '_'..l "_    '                                             Â¢I" Â¢ I_




      Â¢_LffL
          Appendix       D


FLIGHT      TEST     PREDICTIONS

â€¢   Input     Data      (PAIN)

â€¢   Rum     No.    10   (Downsweep)




                   -228-
                                                                                  ORIG_,L      PJ_C_Z :_
                                                                                  OF POOR      Qu,._tl V'



  NASA     FLIGHT        TEST    COMPAR I-SONS :-RUN- NO. i0
1.1012             1.204             334.08         343.0
     21
50.0               63.0              80.0           100.0           125.0         160.0          200.0         250.0
315.0              400.0             500.0          630.0           800.0         I000.0         1250.0        I600.0
2000.0             2500.0            3150.0         4000.0          5000.0
9.27               0.84              50.0           0.33
CABIN      LENGTH        = 7.89      METERS?     FUSELAGE       LENGTH     = 9.27  METERS
7.89               0.00
630.0
STRUCTURAL           LOSS     FACTORS
0.0400             0.0320          " 0.0250         0.0200          0.0160        0.0125         0.0100        0.0080
0.0063             0.0050            0.0040         0.0032          0.0025        0.0020         0.0016        0.0013
0.0010             0.0008            0.0006         0.0005          0.0004
ACOUSTIC         LOSS FACTORS
0.0
0.0
0.0
TRIM      PANEL:        INSULATION        2.1   INCHES      PFIO5+LINING      OF 1.95     KG/M2
0. 055             I. 95             28.10          2.0
0.0                0.0               0.0            0.0
1.6                2.1               2.7            3.3             5.0           8.0            10. I         20.0
30.0               40.0              55.0           80.0             124.0        165.0          223.0         280.0
325.0              360.0             398.0          428.0           460. O
I. 63               1.48              1 â€¢32          I â€¢ 16         O. 95         O. 75          O. 58         O. 47
0.38               O. 30             0.25           0.21            O. 17         O. 14          O. 115        0.01
0. Og              O. 065            O. 055         0. 050          0. 045
1180.0              1179.0            1177.0         1175.0          1170.0       1165.0         1150.0            1130.0
1110.0              1070.0            1035.0        980.0           920.0         865.0          805.0             735.0
675.0              620.0             580.0          550.0           525.0
1.7                2.3               2.9            3.5              4.0          4.5            5.8           7.2
9.0                 11.5              14.5           18.5           22.0          23.8           25.8          26.8
27.2               27.0               26.3          25.2             23.8
PROPELLER          TONES
  FOUR     BLADE        DOWTY     ROTOL:     2.69   M DIA,      1568 RPM,     CLEARANCE=O.06        PROP    DIA.
2.35               75.0               1.12          4.0              1568.0       +1.0
        5       16         S
      1       1    O. O0       1.52      i. 02         I        -.91667E+02              .37323E+02
      1     â€¢ 1    0.00        1.52      1.02          2        -.52304E+02              .6614:3E+01
      i       1    O. O0       1.52      1.02         3         -.11721E+02             .I1487E+01
      1       1    O. O0       I. 52     I. 02         4          .29884E+02             .19901E+00
      1       1    O. O0       I. 52     I. 02        5           .71876E+02             .34483E-01
      1       2       .15      I. 53     i. 02         I        -.11272E+03              .:37273E+02
      1       2       .15      1.53      1.02          2        -.94720E+02              .67555E+01
      1       2       .15      I. 53     I. 02         3        -.75439E+02              .12022E+01
      1       2      .15       1.53      I. 02        4         -.55057E+02              .21367E+00
      1      2        .15      1.53      I. 02         5        -.33556E+02             .37906E-01
      I       3       .29      I. 57     1.02          1        -.13034E+03              .36975E+02



                                                          -229-
                                 IÂ°             â€¢



                _m




                P
                     N Â¸




                     8
                     N




                p




                             8
                                   ilii
0
0
N



                                   iii!
              i
p.*                          8




|




                                       o   ,    â€¢   i                                                                eeooo
V_
                                      _dll     WrP,   04         If",   ,   _       <
u_                                                                                      mmm_
                                                                 pe_        poe


C_
                                                                                            -I
                     O                                           0''        I",,, ,     _'- ,L_        O,     ,L
                                                             4     â€¢           â€¢           â€¢  i)        â€¢       ,    eeoeo
Z                                     ,,,_l_   iii,(             ,_p"       P',,i
144                      o                                       1'Â¢9'      l'Â¢Ii
                                      p,0p     p,ll-   u,-O i ,_ p,_ ,      lull

                                                                                                  I
q                                     ,,,*Â¢    I_*P                         1"4,
                     m
a[
Â¢_
14,                                                                         I,,,I   _                               P'_   p4   p_    P_   _

                                                                                                                                          I
e_

U.                                    _         Â°
                                                                                                       _0
       pm_
_j                                                                          a,,,l _



                     O                                 I_., .I   Wp                         m _        ,L-,
                                                                                                                     â€¢           â€¢    q       â€¢
                                      g         â€¢
Q[
ILl

                                                                                                   I



                                                                            i i !!i
Â¢L

C[     s"
                                                       _'Â°
_L     O"                                      _p


 kl,

                                               OÂ¢
       14.1     o=                                                O
       .,_    Z.C
                                                             f    _
 d*

 I"                                                                                                                                           !
 Le_
 Om
                                      l,,,l
                                          _    ,a_e,




                                                                                        -_}o,                                             1
                     i                                                                  I                                                 i       omm_wm
                             let(m
                                                     ++
                                                      l+!+j
                                                        !I
                                                       mw_m_
                                                       0Â¢    0Â¢:_




RI_
                O
                Q
                             ml,.
                             oÂ¢




                             OÂ¢
                                                           il;;                                            ,             IDa,




                             O--

FF                            â€¢      i                                                                                     â€¢        I


                                                                                                      m        _.               _,
                p_




                O
                                                                                                      _m_C
                                                                                                      _QO-c




                O                        N_                  N            t'_ ,_Q _mm       I
                ,0                         â€¢     Â¢
                It.
                             N_




                m      _lg   I1_,1                           0            m     ,(   (I.                                 _0
                                          â€¢      Â¢
                                         m_                                                           O.       mO_
                                                                                                      m        ,,,tO            â€¢

                       O
                       N

                                           â€¢     i
                                                             e.d          ,_    en   ,4"              _,       _W. ,,0          ,4



      7
                                                                                                                     I
                O                                                         eD    ,d   8',-
                                           â€¢     Â¢



      O         _      =     p_p



                m      L     I_111
                _,.    z.                                                                       L

      x                                  w41_,
                       w_



                I_     tn    mf
                N                          â€¢     q
                              dP_                            m            ,,0   el   o
                             _J
                       _L                elm



                O
                                           Q     _
                                                             ..':2
                             _P
                                         M_



                "41"         OG
                m                          â€¢     q
                lib
                                                                                                                         dP_
                             _w          _p                                                                              eq,_



                                                                                                                         O,C

                m




                O
                <r




                <1"

                O
                             i!          U'_C
                                          â€¢




                                         t_,8

                                         (l'Â¢
                                              q




                                         I_ml em



                                                             Â¢_     !OC              (D
                             0Â¢          _C
               ,emil         Â¢=Â¢
      _C       :l--                        e
                                         K'._"               t_           uP*l_      ur_
                                         ,4"t_
                                         eme _,,

                                                                                                    Fq='       ,at       _,,(
           i                             _m-e-
          ee




Â°Â¢)c_c)
    â€¢   â€¢       â€¢       â€¢   l)   â€¢
m           -   -   -




                                          IiII!If
                                                Â¸IIJJ
                                     Nm
                                          i ||!
                                           MI    m.,m.mm,    o@
                                                                     | i | | i i iT_T_TIT7 | _T_71
                                                                  O_e,_,6IOt,            NaW_   I       l,i-i,,kl,,.,,d._VOl,im_            _'mm,.C_,w_,.m_'wia   ' !
                                     â€¢ -+ - _ â€¢ , "_         "     â€¢ * -+        "_      â€¢ â€¢ â€¢ I        I "_      "+    "+     "+     "      " -_Â° + "@     " ' " )

                                          7 77 7                      7777                      I I'_,:l,,_,i-,_'
                                     â€¢ _-_-_-_               â€¢     -.._-_'_-_-                  I       ]-.._-_                â€¢ _ â€¢         -_-'_-_        â€¢   â€¢ â€¢   _




                                     "7"7"7"7""7"7"7+7"iI'_I-_+_,+_+_-I
                                                                    7=_-_
                                                                        -

                                     ?!il?l!l(                                                                                                                        (


                                     o..+_,'+o._.+e.-.gmP,        k_-.-t_-_cP_r$_...io          I',-,   lm_Im_l_<:ie,.,cl_e4cP_e-.-+e..,-+_,_e-                       l




                                     !!!I!i++I!++!
                                            !!++!
                                               !+!!+!+
                                                   ii!+
                                                      !
                                     â€¢::]+++!i?+ I
                                     ,I- : - : .T.7. .J.                                                        .-.-?!+i.!
                                                                                                          .,...J+:++.'Â°:'     .-
                                                                                                                          '.+'+.t+
                                     ,:l+
                                       i-l,:l-
                                            1-+Â°il-!-?-I                                                                                               +j+.-
                                                                                                                                                          i
                                          I I I I I I I I I I_"7 7"_'_'I
                                                                      7?'iI 7"
                                                                   w                    w




                                      N_e




                                      m,_ c.w
                                      ,,0 ,,0 w_       P
                                                           :!:i!illi i
                                       â€¢    @    â€¢             eee




                                                                                                        !
         â€¢,._V     0',P4.4"I          Wf'_.40"m
 â€¢     E  â€¢          â€¢  â€¢   â€¢           â€¢  @ â€¢                 l@ooo                                     â€¢    4            e     â€¢
_m
           â€¢,0o.,+,
           aDqu        I',F P,-   p             1041
                                                                                                       m ,,_
                                                                                                       0   I_
                                                                                                                         0
                                                                                                                         m
                                                                                                                              I..i
                                                                                                                              QI
                                                                                                       e,q I,-i          _,._     [                     e,,le.qew_                     _m
                                                                                                        I        II
m,ii                                                                                                   0        m        ,..*       m
 â€¢     q                                                       eeoc                                                                           o           â€¢     â€¢        d
                                                                                                       m*Q               O,Q
           Â¢;c
           CPC
               _**C_IDa                ***
                                      _WC

                                                                                                                 I1
           P,,.<   _NO_               O.e_teet,w
                                                               ooooo                                       â€¢      â€¢        e,           â€¢     â€¢           â€¢     â€¢        @        â€¢      Â¢
                                                                                                       N        ,,,_     ,,0"       Â¢1
_m         Â¢_C         0tÂ¢_C                    Â¢_Â¢                                                                                          p* fll            _13 _3         _r,      I',.
                                                                                                                                             tml Iml           i_I  ii                 im
                                                                                                                 II

                                                                                                                                             _N_C
                                                               â€¢           â€¢    â€¢   eo



                                                                                                                                             _II
                                                                                                                 tl                                             I



                                                                                                                                               III114




                                                               o@ooo                               L                                                                oe            â€¢       _




                                                                                                                           |         |1       l         il



                                                               e_oeo                                                                           oeo_o4



                                                                                                                  II       I        ,,,w

                                                                                                                                     *l III                                              I

                                                           t'1'1 eq, C=_ N                  ,4P'
                                                                                                            â€¢       ql         â€¢        Â¢



                                                                                                                           |         |i       I         II      I             _
                                                                                                                                                                                         I



                                                                                                            â€¢       4          â€¢        ii     oe_o_
                                                                                                                                             _N_
                                                                                                                                               O          il                  _          I
                                                                                                                                                                               I



                                                                                                                                                   eeoeel
                                                                                                       J.IjJ
                                                                                                       _-* e,q


                                                           _           1       _
                                                                                                                    Ii          â€¢         ii .oqoqo,
                                                           ,_,,_ _ ,4

                                                                                                           I

                                                           _.          ,,0 .0       Â¢       O
                                                                                                                                                   elod



                                                                                                                                              _|
                                                                                                                                                                         I|




                                                                                                                                                   el                             e,
                                                           ir,_        i+,i wPl iI," i_,
                                                             v         w




                                                                                                                                                                                                  o
                                                                                                                                                                                 OC           o   o            I_
                                                                                                                                                             â€¢ ",     I   II      I   I
                                                  _o                                                                         LU I        _ I_,- U,            _      u4_         Ua4_
                                                                                                                                                              ,I.    0111        CP_-

                                                                                                                             _'     mo,-i

                                                                                                                         w
                       sr



                 Q
                                                                                                                             â€¢ ,,_ ll_lf              _I_.                                                Â¢1
                                                                                                                             Im          ,,r    .iI                              _C
                     io.
                               "C                                                                                            0     ."9    0    _


                     r,L                                                                                                                                                          o
                     _o
                                                                 g                                                                                                                                    â€¢   Zl

                      1.9                                        Z
                      z
                      N                                                                                                                                                                                             i
                     _z



                       q*                                     in                                             Z
                                    I[I                                                      _1[.I
                     bo             u_    I                                            q
                                    Â¢_
                                    7
                                          I                      _C
                                                                 f'b             Is"                                                                                                                           A
                     IQ,.           *-    I            u_                                    C:,        "q                                                       â€¢   _._   _,_   or.
                                    ml    I                                                                                                                  0         â€¢          â€¢       q
                     _rsb           _"    I            ,a                                    q_.l ,,q
                                    _,_   I            .1                                                                                                                        _L. i.,
                                                                                                  o_l        _     _u_                                                           _..i 14
                 . i t,,.J          k.    I            4k                                    "_         .a
                                    C"    I                                                                  _     m                                                                                      Z    111
                                                       ,11
                                    _'J   I            Z
                     b_             u_    I                                                  ..I    "q
                     F â€¢            C_    I        w                                         .,m,_ "q
                                    r._   I   m 91                                           O,.I,,I.q
                                              ik_lm
                     FZ
                     IC             _[    I
                                    Â¢_    I   Â¢?                                                                                                                                 m_
                     PI_            u_    I   _.*u.
                     Jqf                               C                                     tl_        .I         Â¢
                                    Z     I                                                                  2     Â¢::
                                          I                                                                  Â¢     !1 G.
                                                                                                             I-

                                                                                                                                                                                                          -
                     I '._'_              I   I.-C
                                    I--   I   w2
                                          I                                                                  _     u
              i"
                                                                           n
                                              0         â€¢
                                    _'    I
          ,o,i .."                  7     I                      _.*       I,_   'r    III                                                                                       oÂ¢
                                                                                                             2     "--_'

          ":f[
           2".                                ._..i)                                         41.        ,_



          _      mp ]L.

          X      4     _                                                                                     Â¢                                                                                            Â¢
                       Im




                                                                                                                  -255.
ms


     dl
c
                                                                                                                                        0_   [,_c-._
                                                                                                                                        0.-"I
                                                                                                                                           PC

                                                                                                                                                                                      .Â°.




                                                                     --         m




                                                                     j:
                                                                          I.,               i



                     L                                               V_
                     X

                                                                                mC                   _C


                         â€¢           m
                                     ,el
                                                                                _(J"            qn Int,,. _
                     &It.                                                       F




                     Z               _

                                     I

    Â¢
    en




                     :1"
                                               N
                                               Z

    ,.j              r/                        0
                                                I-         0Â¢             0         ,,Oe             _,a,-

    :t               L           _                    f_
    a                                          D                t_

                                                      ,9[
                                                      ua.._
                     _               0         _J
    3
    Â¢
                                                      C_
    aJ.                                               tmO                 4         4,           I    !      !
    0                                          Q_
    41                                                U.O4k
    0                z               _         L
                                                      t,.- 4_             _ _ ,tIP n,e .el" (_,
                     0               0..              2.4
    Â¢                                                 OmO0_
    (.               in              a         LL                               ,       â€¢              â€¢        q
                                                                                    e-re             Ot,_
    I,"                                        Z

                     _               3
                      Z              C
                     b.m             Iii




                                                      2         U_                                                      i
                     Z                                                                                                  n
                                                                                                                        I
                                               I--                                                                      l
                                                     :4J_
                                     ol              1.1(                                                               I
          '11_   b   r               --              :"re
                                               ill
            U.   g   N               r.        Z                                                                        I
                                                                                                                    -   I
I




:1
                                                                                                                        I




                                                                                                                                                                           omm_


                             â€¢             â€¢   â€¢            â€¢                       â€¢                       â€¢               â€¢   â€¢   â€¢    â€¢        â€¢    â€¢   â€¢   â€¢   â€¢   â€¢          â€¢
  1.   Regott       No.                                                            2.   Government    Accession     No.                          3.   Recipient's            Catalog         No.

       NASA CR-172428
  4.   T;tle      and     Subtitle                                                                                                               5.   Report        Date

        Prooe!!er    Aircraft     Interior   Noise                                                                  Model                              September                                  1984
            Utilization     Study    and Validation                                                                                              6.   Performing             Organization          Code




  7.   Author(s)                                                                                                                                 8.   Performing             Organlzation          Report     No.

        T,â€¢D.              Pope                                                                                                                        84-001
                                                                                                                                                10.   Work       Unit        No.

  9.   Performing          Organization          Name      and    Addres_

        L.D.  Pope,   Ph.D.,   P.E./Consulting                                                                      Engineer
                                                                                                                                                11.   Contract          or    Grant         No.
         1776 Woodstead    Ct.,   Suite   111
        The Woodlands,     TX 77380                                                                                                                   NASI-I                    7281
        P.O.  Box 7956,    The Woodlands,      TX                                                                 77387                         13.   TyDe     of       Report        and     Period      Covered

12.    Sponsoring           Agency       Name        and   Address                                                                                     Contractor                                  report
        National    Aeronautics                                                  and        Space        Administratio_                         14.   Sponsoring             Agency         Code
        Washington,     DC 20546

15,    Supplementary                 Notes


       Langley                         Technical                      Monitor:                   William             H.       Mayes


16.    Abstract

 Utilization      and validation      of a computer       program    designed     for air-
 craft   interior     noise   prediction     is considered.         The program,       entitled
 PAIN   (an acronym      for Propeller      Aircraft    Interior     Noise),     permits     (in
 theory)    predictions      of sound    levels    inside    propeller     driven    aircraft
 arising     from sidewall     transmission.        The   objective     of the work       re-
 ported    was to determine       the practicality        of making     predictions       for
 various    airplanes     and the extent       of the program's        capabilities.         The
 ultimate     purpose    was to discern      the quality      of predictions        for tonal
 levels    inside    an aircraft     occurring     at the propeller        blade    passage
 frequency     and its harmonics.         The effort      involved     three   tasks:
                    I)               program    validation      through    comparisons    of predictions
                                     with   scale-model      test   results,
                    2)               development     of utilization        schemes    for large   (full
                                     scale)    fuselages,     and
                    3)               validation     through     comparisons      of predictions    with
                                     measurements      taken    in flight     tests   on a turboprop
                                     aircraft.

 Findings                            should  enable                              future   users    of the program                                         to             efficiently
 undertake                            and correctly                               interpret     predictions.



17.    Key     Words        (Suggested          by   Author(s))                                               18.    Distribution   Statement

         Aircraft                            Interior                  Noise
         Propeller    Noise
         Sound   Transmission



19.    Security         C_assif.     (of this    report)                                                                                                         22.         Price

       Unclassified                                                              Unclassified
                                                                            20. ,Security Classif. (of this page)




                                                                                                     -238-
```
