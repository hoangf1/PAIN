# NASA-CR-3813 methodology (OCR extract)

> Machine-extracted text from the corresponding PDF. OCR errors are expected; prefer the PDF for authoritative wording.

```text
NASA Contractor Report 3813




Propeller Aircraft
Interior Noise Model


L. D. Pope, E. G. Wilby,
and J. F. Wilby



CONTRACT NAS1-15782
JULY 1984




NASA
NASA Contractor Report 3813




Propeller Aircraft
Interior Noise Model



L. D. Pope, E. G. Wilby,
and J. F. Wilby
Bolt Beranek and Newman Inc.
Canoga Park, California




Prepared for
Langley Research Center
under Contract NAS1-15782




NASA
National Aeronautics
and Space Administration
Scientific and Technical
Information Branch

1984
Page intentionally left blank




Page intentionally left blank
                        TABLE OP CONTENTS



Section                                                   Page

1.0   SUMMARY                                              1

2.0   INTRODUCTION                                         2

      2.1   Report Organization.    ............           5
      2.2   Program Management                             6

3.0   ELEMENTS OP THE PROPELLER AIRCRAFT INTERIOR
       NOISE MODEL                                          7

      3.1 General Solution for the Sound Transmission
           Problem                                          8
          Power Flow                                       10
      3.2 Transmission of a Tone                           14
          High Frequencies                                 16
      3.3 Calculation of the Noise Reduction               21
          Noise Reduction Calculation                      22
          High Frequencies                                 23
      3.4 Calculation of the Generalized Forces for
           Propeller Noise Excitation                      26
          ANOPP Computer Program Output                    26
          Geometrical Considerations and Reflecting
           Surface Effects .                          .   31
      3.5 Interior Coupling Factor f'(n,r)                32
          Calculation of f'(n,r) for Cylinder
           with Floor                                      33
      3.6 Joint Acceptances for Cylinder with
           Structurally Integral Floor                    36
      3.7 Resonance Frequencies.                 ...      40




                                   iii
                            TABLE OP CONTENTS
                               (Continued)

Section                                                    Page

     3.8     Loss Factors                                  40
             3.8.1   Acoustic Loss Factors n and n . . .   41
                                                n    n
                     Bare Fuselage (Cabin)                 41
                     Calculation of n    when sidewall
                      trim is present                      41
             3.8.2   Structural Loss Factors               42
                     Influence of trim on structural
                      damping                              43
                     Influence of internal radiation:
                     closely coupled structural and
                     acoustic modes                        43
                    Average radiation loss factors. ...    44
     3.9     Validation Studies                            44

REFERENCES                                                 45



APPENDIX A -.SIDEWALL TRIM: TRANSMISSION AND
              ABSORPTION MODELS

Transmission                                               A-l
Trim Transfer Matrix                                       A-5
Sound Absorption                                           A-8
Vibration Transmission to Trim                             A-9

APPENDIX B - FUNDAMENTALS OF PROPELLER NOISE THEORY. .

APPENDIX C - CABIN ACOUSTIC MODES

 Finite Difference in Two Dimensions                       C-l




                                    IV
                        TABLE OF CONTENTS
                           (Continued)


Section                                                     Page



 Boundary Conditions                                         C-4
 Solution                                                    C-4
 Normalization                                               C-6
 Sample Results                                              C-7

APPENDIX D - FUSELAGE STRUCTURAL MODEL: CYLINDER WITH
                 INTEGRAL FLOOR


 Displacement Functions                                      D-l
 Constraint Equations                                        D-3
 Equations of Motion                                         D-4
 The Mode Shapes (Eigenvectors)                              D-10
 Generalized Mass                                            D-12
 Sample Output                                               D-12


APPENDIX E - MODEL VALIDATION STUDIES.


 Test Hardware                                          ^    E-l
 Propeller                                                   E-5
 Test Description                                            E-8
 Measured Interior Sound Levels                              E-12
 Propeller Noise Field                                      E-l-4
 Acoustic Loss Factors                                       E-18
 Structural Loss Factor                                      E-21
 Predicted Interior Sound Levels                             E-24
 Noise Reduction                                             E-30
 General Comments                                            E-39

APPENDIX F - LIST OF SYMBOLS
                        LIST OP FIGURES



Figure

1.    Propeller Aircraft Interior Noise Model              3
2.    Propeller and Fuselage Surface Point Geometry . .    4

A-l. A Basic Sidewall Trim: Insulation and Lining. . .    A-2
A-2. Acoustical Properties of Owens-Corning PF-105
      Fiberglas: Density 9.6 kg/m3 (0.6 Ib/ft3),[21] .    A-6

B-l   Lagrangian Coordinate (ri) System                     B-6

C-l   Cabin Acoustic Space                                C-2
C-2   Finite Difference Grid Nomenclature . . . . . . .   C-3
C-3   Acoustic Modes for a Case where 6O = 56.6Â°,
       q = 0, a = 1 meter                                 C-8

D-l   Circular Cylindrical Shell with a Longitudinal
       Partition                                          D-2
D-2   Example Shell Mode (Z Dependency Suppressed). . .   D-17
D-3   A Second Example Mode                               D-19

E-l   Model Test Facility (Dimensions in meters). . . .   E-2
E-2   Fuselage Model                                       E-3
E-3   Floor Assembly (Dimensions in meters)                E-4
E-4   Grid Used for Propeller Noise Predictions . . . .   E-6
E-5   Cross-Section of Test Cylinder Showing Trim . . .   E-10
E-6   Microphone Locations in Test Cylinder               E-ll
E-7   Typical Narrowband Spectra of Interior Sound
       Pressure Levels                                    E-13
E-8   Average Sound Pressure Spectra in Cylinder at
       Different Measurement Stations (Propeller Noise
       Excitation)                                        E-15




                               VI
                          LIST OP FIGURES
                            (Continued)


Figure                                                      Page


E-9      Space-Average and Range of Values for Propeller-
          Induced Sound Levels Inside Test Cylinder . . .    E-l6
E-10     Space-Average and 95% Confidence Limits for .
          Propeller-Induced Sound Levels Inside Test
          Cylinder                                           E-17
E-ll     Measured and Predicted Free-Field Sound Levels
          for Test Propeller.                                E-19
E-12     Measured and Predicted Blocked Sound Levels
          Induced by Propeller on Test Cylinder              E-20
E-13     Measured Acoustic Absorption Coefficients in
          Test Cylinder                                      E-22
E-14     Measured and Predicted Acoustic Loss Factors for
          Interior of Test Cylinder (5.1 cm Fiberglass
          plus Trim)                                         E-23
E-15     Measured and Predicted Total Structural Loss
          Factors for Test Cylinder                          E-25
E-16     Comparison of Predicted and Measured Sound
          Levels in Cylinder Induced by Propeller (Mean
          and Range of Values)                               E-26
E-17     Comparison of Predicted and Measured Sound
          Levels in Cylinder Induced by Propeller (Mean
          and 95% Confidence Limits)                         E-27
E-18     Comparison of Predicted and Measured Sound
          Levels in Cylinder Induced by Propeller (Trim
          Loss Factor = 1.0, Total Structural Loss Factor
          Limited to 0.15 Maximum)                           E-29
E-19     Average Noise Reduction Measured at Station
          at 50% of Cylinder Length                          E-31
E-20     Average Noise Reduction Measured at Station
          at 83% of Cylinder Length                          E-32




                                  vii
                        LIST OP FIGURES
                          (Continued)

Figure

E-21   Comparison of Measured and Predicted Space-
        Average Noise Reduction for Test Cylinder
        (Average and Range of Values, Trim Loss
        Factor = 1.0. Total Structural Loss Factor
        Limited to 0.15 Maximum)                           E-33
E-22   Comparison of Measured and Predicted Space-
        Average Noise Reduction for Test Cylinder
        (Average and 95% Confidence Limits, Trim Loss
        Factor = 1.0, Total Structural Loss Factor
        Limited to 0.15 Maximum)                           E-34
E-23   Measured Noise Reductions for Cylinder with
        Different Thicknesses of Fiberglass Batts on
        End Plates                                         E-36
E-24   Predicted Noise Reduction for Cylinder with
        Different Thicknesses of Fiberglass Batts on
        End Plates                                         E-37
E-25   Predicted Acoustic Loss Factors for Cylinder with
        Different Thicknesses of Fiberglass Batts on
        End Plates                                         E-38




                              viii
                       LIST OF TABLES



Appendix - Table No.                                       Page



C-l.   Example Program Output. Phase III Test Article,
        Angle subtended by Floor Edge with Vertical
        00 = 56.6 degrees                                   C-15



D-l.   Example Program Output. Phase III Test Article:
        1.803m (71 in.) long cylinder, stiffened 0.0008m
        (0.032 in.) skin, 0.508m (20 in.) radius with
        floor at 56.6Â°                                      D-13




                               ix
1.0   SUMMARY

An analytical model for aircraft interior noise prediction is
considered in this report. The model can be used to predict the
sound levels inside an airplane cabin caused by the rotation of
a propeller (of any design) alongside. The fuselage model is
that of a cylinder with a structurally integral floor. The
cabin sidewall and the floor are stiffened by ring frames and
stringers or floor beams of arbitrary configurations.  The cabin
interior is covered with a trim (i.e., layers of insulation and
septa with a lining) to increase the sidewall sound isolation
and provide absorption in the cabin.

The results are the culmination of a three phase program
sponsored by NASA Langley Research Center. In Phase I the basic
analytical modeling of the transmission problem (interaction of
the structure with the exterior and interior acoustic fields)
was undertaken and preliminary validation studies were completed
using an unpressurized, unstiffened cylinder as a test article.
Results of that work are presented in Reference [3].  In Phase
II, the general aircraft interior noise model was developed and
preliminary work on the laying out of the basic master computer
program began. Validation studies were conducted using more
advanced test articles (one being a stiffened cylinder with a
floor partition and interior trim). Results of that work are
found in References [4] and [7].  In Phase III, the analytical
models and the software were completed (including the propeller
excitation work). Validation studies using a scale model fuse-
lage excited by a propeller were undertaken and the documenta-
tion of the finalized model and software package was completed.

The present model is believed to be the only one in existence
that can be used to calculate the interior sound levels using as
input data, the precise propeller noise signature over the
fuselage.
2.0   INTRODUCTION

This report presents the details of a basic airplane interior
noise model. The elements of this model include a fuselage and
a propeller (Figures 1 and 2). The fuselage consists of a cy-
linder stiffened by ring frames and stringers, and a floor that
is structurally an integral part of the fuselage. The cabin
space is the volume above the floor. The interior surface of
the cabin (sidewall) is finished out with a trim consisting of
insulation covered with a lining. The propeller rotates about an
axis parallel to the centerline of the fuselage. The model can
be used to predict the sound levels in the cabin space for each
of the various harmonics of the propeller.

The excitation of the exterior of the fuselage is obtained using
a propeller noise prediction model developed by NASA Langley.
The present model works with the pressure time histories (signa-
tures) as defined over the fuselage at a number of closely
spaced points on a grid that lies in the fuselage skin. The
pressure signatures are Fourier analyzed to define the ampli-
tudes and phases of each of the harmonics of the propeller tones
(at each location on the grid). The cross power spectral den-
sity function for each harmonic, for all grid point pairs (a
                                                    \
delta function in the frequency domain) is used to compute the
values of the generalized forces for each structural mode of the
fuselage.

The fuselage structural modes are developed for the case of a
stiffened cylinder with a floor partition. The structural modes
are described by their eigenvalues (resonance frequencies),
eigenvectors (mode shapes), and loss factors. The mode shapes
include not only the cylinder wall normal displacement (w com-
ponent) but also the normal displacement of the floor, and the
in-plane axial and circumferential displacements (u and v
components) of cylinder and floor as well. The loss factors of
F I G U R E 1.   PROPELLER A I R C R A F T I N T E R I O R N O I S E MODEL
                Propeller Plane
                                                     FUSELAGE
                       \



                                                    y - Incidence Angle




                            n




                                  x       = (a, 9, z) = Location of Free
                                      m
                                                        Field Prediction
                                                        Point
                                           (r       ,<t>,: 2 ) = Propeller Position
                                                P           P




FIGURE 2.   PROPELLER AND FUSELAGE SURFACE POINT GEOMETRY
the bare fuselage are input and must come from measurements.
When trim is installed on the sidewall, the structural losses
increase due to the trim's presence against the sidewall and
this is computed for the particular trim installation.

The displacement of the trim lining induced by the fuselage skin
vibration is determined using a transfer matrix which relates
the pressures on the inside of the skin and the inside of the
lining to the displacement of the skin and of the lining. The
transfer matrix contains all of the physical properties of the
insulation and lining required for the calculation. The wave
impedance of the insulation and complex acoustic wavenumber are
input as physical parameters to describe the insulation.

The coupling of the lining to the interior acoustic field is
calculated for each acoustic and structural mode. The acoustic
modes are defined by their resonance frequencies, mode shapes,
and loss factors. The acoustic loss factors must be input for a
bare fuselage but are calculated when a cabin trim is installed,
from elements of the trim transfer matrix.

The model allows for the calculation of the space average mean
square pressure in the cabin for each propeller harmonic, (up to
a maximum of ten (10) harmonics).

2.1   Report Organization

This report considers the analytical derivations, experimental
tests, and validation studies. The analytical derivations are
presented in Section 3 and Appendices A through D. Appendix E
is devoted to test comparisons and to the determination of the
quality of the predictions. Appendix F is a list of symbols
used.

Early in Section 3, general solutions are given for the basic
sound transmission problems of concern. Problems of tone
transmission (propeller) and noise transmission (reverberant
exterior field) are considered. Solutions that are to be used
in the low and high frequency regimes are presented (the low
frequency formulations apply until the acoustic modal density of
the cabin space is equivalent to 10 to 15 modes in every one-
third octave band). Beginning with Section 3.4, the various
terms appearing in the general solutions are evaluated, literal-
ly specialized to create the desired interior noise model.
These terms include the generalized forces for propeller noise
excitation, interior coupling factors, joint acceptances,
resonance frequencies and loss factors. Information needed to
complete these calculations are derived in the first four
appendices.

The model validation undertaken in Phase III is considered in
Appendix E. The experiment and the data acquired are discussed
and a statistical comparison of predictions and measurements is
presented.

2.2   Program Management

The work was accomplished in joint effort by BBN/Los Angeles and
NASA Langley Research Center. The experimental work was done at
NASA Langley by C. M. Willis and W. H. Mayes. Mr. Mayes acted
as LaRC technical representative of the contracting officer
(TRCO). L. D. Pope served as BBN program manager.
3.0   ELEMENTS OP THE PROPELLER AIRCRAFT INTERIOR
      NOISE MODEL

A detailed description of the propeller aircraft interior
noise prediction model is given in the following paragraphs.
It is the intention of the authors to present all of the
background needed to understand the equations and their
origins. This is done partly through the use of a series of
Appendices that summarize the primary results from two
previous phases and the now concluding phase of work that
have led to the present model. References to some published
papers and books are also required.


A concern in this report is to define a reasonable level at
which to begin the technical presentation. This model is
based on the general solutions of sound transmission prob-
lems for cases of tonal and broadband noise excitations.
Parts of the report deal with the theory of fluid-structure
interaction problems with direction at the development of a
sufficiently general solution as needed for the present
purpose. Because the propeller is an integral part of the
model the field of "aeroacoustics" is inherently involved.
Due to the complexity of the fuselage models and the geomet-
ry of the cabin space, the structural dynamics of stiffened
shell structures must be considered and numerical procedures
for calculation of the acoustic characteristics of complex
spaces devised. The presence of sidewall trim (insulation
and lining) leads to the use of the properties of porous
materials.

The ultimate user of this model will not necessarily be
knowledgeable in all of these areas. For instance, one well
versed in the fluid-structure intraction problem may have
little or no experience in propeller noise. Keeping this in
mind, an effort has been made to ease the transition between
the various disciplines and the introduction to each topic
is kept at what might be considered an intermediate level.

3.1   General Solution for the Sound Transmission Problem

The fundamental goal of this model is the prediction of the
sound level inside an airplane cabin due to noise on the
exterior caused by the 'rotation of a propeller. The
propeller noise of concern is at discrete frequencies and is
not really a noise at all, rather a series of tones. The
lowest frequency tone is at the blade passage frequency
(BPP) and the other tones are its harmonics, that is, they
occur at frequencies that are integral multiples of the BPF.
As a secondary goal of this model, predictions for the cases
of an arbitrary exterior harmonic (tonal) field and for a
reverberant exterior (noise) field are sought. Sound
transmission through the fuselage sidewall and the trim
insulation and lining is of concern.

The basic method used herein to solve the sound transmission
problem is that of a power balance.

                        W
                         in 'Wdiss   â€¢                   (1)



The band-limited net time-averaged power, W,.n, flowing into
the cabin must equal the net time-averaged power, W,.    - ,
                                                    Q. J. & S
dissipated on the cabin walls. By expressing the inflowing
power in terms of the exterior exciting pressure and the
dissipated power in terms of the interior response pressure
and equating the expressions according to Eq.(l), one can
solve for the interior pressure.
A primary feature of the power flow approach adopted is that
integration of spectral components has been performed
analytically to achieve band-limited levels, i.e.,



                                                          (2)
                                 1
              W..
               diss = J.
                      f    Reftf
                             L abs"^^!
                                    'J dco

  int
Wracj(co) is the complex spectral density of the power radiated by
the structure into the interior acoustic space and W , (w) is
the spectral density of power absorbed on the inner wall o-f the
space from the interior acoustic field. In the case of tone
transmission, these quantities contain delta functions in the
frequency domain. Eqs. (2) have applicability at all frequen-
cies and can be applied- in discrete modal representations even
when there are no acoustic or structural modes resonant in the
band Aco.

Power flow into each individual acoustic mode is computed,
whether the mode is resonant in the band or not. If the mode is
resonant in the band, one can speak of the "resonant response"
of the mode; if the mode is resonant outside the band, the
"nonresonant response" of the mode in the band Au. Similarly
power flowing out of the acoustic field to the inside wall is
computed mode-by-mode. By equating the power into a mode to the
power out, the space-average mean-square modal pressure for mode
n, limited to band Aco, is obtained, i.e., < p^> , , where s and t
                                              n s $ \j
indicate the space and time averages, respectively. The band-
limited, space-average mean-square pressure in the interior is
the sum


                    s,t,    4   p2n> s,t.    '                  (3)
Here n is the complete set of acoustic modes, i.e., those
resonant inside Aco (denoted by the symbolism, nsAw ), as well as
those resonant above (n>Aio ) and below Ato (n<Aw ). It is noted
here that the letter "n" always denotes acoustic modes and the
letter "r" structural modes, usually being used as subscripts,
superscripts, or indexes.

Power Plow

The concern is with a closed volume V, into which sound energy
is propagating. The excitation of the space occurs at its
boundary with the enclosing structure which vibrates due to an
exterior source. For the present, the excitation can be consi-
dered to be a broadband random acoustic field. For the specific
case where the noise reduction is desired, the exterior field is
taken to be diffuse (reverberant).

The fundamental equation for the inflowing power comes from
results developed in Refs. [1] and [2].  Specifically, use is
made of Eq.(3) of Ref. [2]:




   WW   - P o * cS   ,     J (
                            r ">
     in     V
                             r r      n     n

                /




W. is the band-limited time averaged power which is being
accepted by the acoustic field inside the enclosure, that is,
the power received over frequencies lying in band Aw . The band
has a width Au = c cu where co is the center frequency of the
                  CO
band. c is a constant percentage which defines the bandwidth



                                 10
(cw = 0.232 for one-third octaves). The quantity Spbl(co)
= <p^>/c co is the power spectral density of the average
exciting "blocked pressure" which acts on the transmitting
structure. <Pbl> is the average mean-square pressure as would
be measured in band Aco obtained with a microphone sampling the
surface pressure on the (hypothetical) immobilized (blocked)
structure. The transmitting structure has an area A exposed to
volume V. The average surface mass of the structure is m. The
structure has a mass law sound transmission coefficient T^ =
(2pcQ/com)2, where p and CQ are the density and sound speed of
air.

The normalization of structural modes is taken such that the
modal mass is
                         f    _ r2 _ _
                   M = J- m(x)4> (x)dx     ,
       3? ~                                                    â€”
where ty (x) is the structural mode shape (mode r) at location x.
x ranges over the entire structure, both transmitting and
non-transmitting surfaces. Thus, if the rth mode of the
transmitting structure (fuselage) is restrained in any way, say
perhaps by the cabin floor, Mr will take on a large value that
will suppress transmission by that particular mode. The
normalization of the acoustic modes is such that

                       f 4>Â£dv = ^L
                       Jv n      n
where <)>(Â£) is the value of the cabin acoustic mode shape (mode
n) at location f.

The coupling of the exterior field to the rth mode of the
transmitting structure is given in terms of the joint acceptance
 o
jr(co). In the case where the exterior field is a noise it is
assumed that jr(w) changes little across Aco, i.e. by evaluating
j2(co) at the center frequency of the band, a good approximation
is obtained all across Aco. For this reason Aco must not be too
wide, typically one-third octave or less. If the exterior field

                                11
is reverberant, Jr(oO takes the appropriate form for that field.
The same would be true for a progressive wave field.


The coupling of a structural mode to an acoustic mode of the
volume is given by the term



                                 â€¢'A
In the above, x represents a point on the surface of the
transmitting structure.       Note that f'(n,r) is non-dimensional
(hence the prime as a reminder) and that f'(n,r) is always
squared. f'2(n,r) is a positive number less than unity. The
power flow depends on the location of the resonance frequencies
^n and for, i.e. relative to each other and to the band Aw, and
upon the acoustic and structural loss factors nn and nr.

Consider now the right-hand side of Eq. (1). W^gg is the
band-limited, time-averaged power that flows out of the interior
acoustic field to the inner wall of the enclosure. This power
flow is given by Eqs. (6) and (8) of Section III of [2] which
reduce to
                                             2

              W
                  diss ~ ~7      2-r        uT< p n > s , t   '        (5)

                          o       n
        2
where <p >     is the interior space-average mean-square pressure
        n s^ u
in band Aco attributable to the nth acoustic mode. The develop-
ment of Eq. (5) is presented in the appendix of [2].

In the case of a random exterior field, in which Sp               (03) varies
                          w
slowly in frequency, jr( ) can be brought outside the integral
as done in Eq. (4). However, for the general circumstance where
tones are present, jÂ£((o) must be included under the integral
sign, and replaced by its defining relation

                          'pb -.(xlx
                              _L
                                     ;<jo)^r(x)^r(x )dxdx

                                   AÂ«S p M <Â»>

                                       12
where C    (xlx'uu) is the cospectral density function of the
       pbl
blocked exterior pressure field.

Also, in order to get Eq. (H) in the desired form for the
present model it must be modified in two other respects. First,
to include fuselage sidewall trim, Eq.(4) is modified to include
factor T , i.e. the trim transmission coefficient, to account
        U
for transmission through the trim, and the structural loss
factor ri is replaced by ri' to account for the added
damping of the sidewall when trim is present. Second, proper
account of the influence of the internal radiation damping of
structural modes leads to the introduction of another term, H".
The analytical developments for T, and n' are given in Appendix
    ii
A; ^p will be discussed in a subsequent section.   After some
rearrangement and the inclusion of the above results, Eq. (4)
can be written in the following general form



            Win _ 2TT /mAV
                ~ PV ITT)             to-n


               V II ?n,r)             (x |xlo))ij;r(x)^r(x')dxdx'
               //   IV
                    "

                                                               (6).



A bar over f'(n,r) indicates trim factor T,t has been introduced.
Eq. (6) is basically the same as Eq. (21) of Ref. [3], except
modified to include trim and the proper influence of the
internal radiation damping of resonant structural modes closely
coupled in frequency to resonant acoustic modes.




                                13
The solution of a sound transmission problem is obtained by
setting the nth term of Eq . (5) equal to the nth term of Eq.(6),
solving for the individual modal pressures <p,?>
                                              n s $.u one-by-one,
and by adding the results according to Eq. (3), to obtain the
interior level.

3.2   Transmission of a Tone

The fundamental model of concern here is one having to do with
tone transmission. The propeller noise is, as stated, at
discrete frequencies, each tone being a harmonic of the BPP.
Let the various harmonics be u   u   . . . , to H where

                            w
                               1 = 2 ir x BPF
                            a) 2 = 2(x)]_
                            o>H = H"! ,

where H is the harmonic index. For a tone at frequency WH>
the co-spectral density function is defined by


               C pbl (x|x f ) 6(co-uH) = Cpbl(x|x' ;u)         ,


           Cpbl(x|xf ;u>) = 2 Cpbl(x|xf ;co) ;         0 < co < Â»   ,

                                         oo

       Cpbl(x|x';co) = Re                f


where Rpbl(5c |x' ; T) is the average cross correlation of the
pressure over the blocked (immobile) fuselage, given by

                                    u_
 R                      ^       /        Re[pbl(x,t)] Re[pbl(x',t+T)J dt
 "
Inserting the first of the relations into Eq . (6) leads to the
expression for the inflowing power to the cabin for the
propeller tone at frequency WH-
                                                                  e
               w in = pV
                       â€”                        2       ,         n%
                                                                   n
                 .y- f " ( n . r ) f f                                           ^        T*   ^    â€”   â€¢â€”
                                                                              'xH              (x1 )dxdx'
                  VÂ«                    JJ
                                          x x


                                                                                                                 (7)




                       H                H           â€”
In this r e s u l t , TML
                       M T a n d Ttf (in f ' ( n , r ) ) are evaluated at o> TT .


The space average mean square modal pressure is computed on a
mode-by-mode basis using Eqs. (1), (5), and (7) (where u= U



         2>H                                H   "H        Â£
                                                              n             f'2(n,r)
      <Vs,t
                                                     11               j.             J.   j.


                      if         Cpbl(xjl')/(x)i);r(x')dldx'
                       XX '




                                        2 \2                               2 \2
                                                                                                             .     (8)
                                   0)
                                                                           H \

                                        n


The interior space average level is then obtained from Eq. (3)
Note that since
                                                          H
                                                <P_n2 >
                        <P
                             n    s,t4.             V




                                                          15
where <P^> is the mean square modal amplitude, the modal ampli-
tude is determinable from
                      2 H        2 H
                   <P
                    F >   = e <p
                     n       n pn >s,t
                                     ,
                                          '
and theoretically, the mean square pressure at every interior
point can be obtained with



                             n
It is emphasized here that a good point-by-point prediction may
require better input data than can ever be generated, but the
point-by-point prediction might be quite informative neverthe-
less .


Eq.(8) is the fundamental result for calculating the interior
sound pressure level.     The modal forcing functions are given by
the term


              yG(r,H) =    J J Cpbl(x|x')4;r(x)4;r(x')dxdxI ,     (10)
                           X X'
and must be evaluated for the propeller noise excitation.         Once
a particular harmonic H is chosen, the function 'fG(r,H) must be
computed for all structural modes r.     The calculation of yp7(r,H)
using the output from the ANOPP program [Ref.5] is considered in
Section 3.4.


High Frequencies


When the acoustic and structural modal densities are large
enough, the transmission can be expected to be dominated by
modal response close to the excitation frequency.      Only the
modes lying in a narrow band Aw containing co^ need be of
concern.   Thus at sufficiently high frequencies the space



                                   16
average mean interior pressure for harmonic H is (assuming
that only the sidewall contributes)


      P
       2
     <n^>"        =     il I ""' I TnnTT.&Ju
                                               v**/
      i s,t           "2 ITTJ      ML   w
                                         t H L*,




                                                             (11)


To facilitate the calculation of Eq.(ll), it first is rearranged
(keeping in mind that ^G(r,H) is computed for high frequencies
for each structural mode as it is for low frequencies, but the
calculation is limited to those modes whose resonance frequen-
cies lie close to co,,) . Define average loss factors for the
modes near co.,, i.e., let



nr    is the average loss factor for the structural modes.
Also, let



                                                      -l


                                                      1-1


             Q     _^  \j i luji i   __ ri n. 6
                                     T
                 H - -71 IT]          MLTtwH




                                               17
Then Eq.(ll) can be written as


                                         f'(n,r)grYG(r,H)
                                                                  (12)
                  neAo)         n   0)
                                              r r
The interior response is sought for the case where con and cor
are given equal probabilities of lying anywhere in the band AGO.


Eq.(12) can be simplified somewhat by noting that the resonance
frequencies are approximately equal to the harmonic frequency
o)IT of concern,
  n

           IT          Q
           "
           s,t                                                    (13)

The expected value of the above is now calculated given &Jn and
wr as independent random variables uniformly distributed across
Aco.




                            Q
                 = E



                    QH_
                            N
                       'H



In Eq.(lM) 5 N r is the number of structural modes in AOJ and N
is the number of acoustic modes in Aw.




                                         18
Now



                  Aco
where        is the p r o b a b i l i t y density f u n c t i o n for co n in Aco.

The probability distribution function is taken to be simply

                                              1
                                              -
                                   Aw

The probability density function is therefore simply

                                dP(wn)            1
                                                  Aco
                                   do)n
so



                              Aco
that is E[g n ] is j u s t the average
                                     , Aco


                                                            n
                                    Aco
                                                        H       n
which becomes

                 0)
                  H
                         tan"                     tan -l




Assuming that the product n cou Â« Aco (this can be assured by
                           n n
taking the sampling band wide enough), the term in the brackets ,
[ ], above reduces to IT, giving


                           {0 â€¢ -
                            L nJ        On




                                             19
S i m i l a r l y , i t can be shown t h a t
                                                 TO,




S u b s t i t u t i n g i n t o ~ q . ( 1 4 )g i v e s




~~t nn = N,/~Y             i s t h e modal d e n s i t y of t h e a c o u s t i c modes*    and


       n~ = N r / A o      i s t h e modal d e n s i t y a f t h e s t r u c t u r a l modes.

Therefore




 where




 I t c a n be shown t h a t

                                            u ;Iv           rev
                                2
                     n < c n f q(n,r)>nw - -     M
                                                         jp,)        .
                      n                     n2c;
Substituting this result gives


                                 n f-^
                                  r ML           1,1   11        -v'   - ( i ^ - 3*- * *'i r..   \\   (If,}




In (16), AOJ is taken just wide enough to assure smoothness of
the average calculated in the brackets.

3-3   Calculation of the Noise Reduction

In addition to the calculation of transmission of propeller
noise, there may be occasions where the noise reduction of the
fuselage is of interest, that is, for a condition where the
exterior is bathed in a reverberant (diffuse) acoustic field.
For such a case, the expression for the inflowing power is again
obtained from Eq.(6). However, in -this instance, the joint
acceptance can be reinserted and brought outside the integral as
in Eq.(2). Then after the integration is performed, it is found
that [2]

            2    -j.                    2
        p
         bl            2TTA 2 / m A \
                                            T
 in "   c^              pV \~$~ )               ML '    n




                        M*



        (
        2c (b -b )-b (c -c ) \
          n r n     n r n \
                              I arctan


        2c       (b   b ) b (c
                r
                r n-n ri ~ r  n-cr) i ^-^^-t-^^
                           i _LL.â€”â€”Â±                                       \                             (~\ 7}
                                                 2
                       â€¢ N 'P + n'jÂ»' ' j>)w
 where A is the cylinder surface area and A is the coupling area


                                                            21
For n or r = j,
                                             /2)*a3"+b.(l+c
             In. = In
                                 (1-c        /2)lto)''+b<(l-c / 2 ) 2 o > 2 + c . |              (
                                        0)                      J            0)         J        '

                                                   2
                                 1 (2+c OT) co - Jo)J
                                                          2 i       2
                                                                                    â€¢( 2 - C a ) ) 2 a) 2 -S
       arctan. = tan
                      J
                             r                                               -tan
                                                 ^.O) 2                             .       ^^i

where when j = r, n . above = n^, + n'' , and when j = n, n . = n
Also
                 D
                  nr                              <b,Tbr>(bncr ' brcn}
                  b
                      n = -2<     J br = -2<                            ,

                  c
                      n=                                    c        =
The above is identical to Eq.(5) of Reference [2] except that
f'(n,r) replaces f'(n,r) and n'+n^l replaces nr-

Noise Reduction Calculation

The interior pressure is obtained by setting W in                                                              (using
Eqs.(17) and (5)) solving for the mean square modal pressures
<p 2 >   one-by-one, and adding according to Eq.(3).
  n s$ u

The result is found to be
<P2i>s , t  8 P_ /mA
             =
                                             T
   ?>â€žs,t " V V2 \ H
<P e
                                              ML Â°o
                                   rev _ 2
                                    Â«) f'fn.r)                               â€”/->
                                                                            r cn    In n
                                   M2 D
                     n              r nr

                                             -bn(cr-cn)
                                                       â€¢ Iarctann                                               (18)

                         /c -c                         2cr(bn-br) -br(cn-cr) \
              +          / n r    In +                                                               arctan
                                    r
                                                                                               /

                                                                22
where the exterior space average mean square pressure <p 2 >    is
                                                         G Sj U
(for the reverberant field) related to the mean square blocked
pressure by

                        <p
                         P2>    4.
                            e s,t


High Frequencies

When the acoustic modal density is greater than, say, ten or
more modes in a third octave band, a high frequency model is
needed, developed along the lines of [1,2, and 3]. In the case
of an added trim, there are three surface areas of concern:
1) the transmitting area with trim, which will be called A fc ,
2) the absorbing surface area S, and, 3) the transmitting area
without trim A1.      The total transmitting area is A.+A' and
the inflowing power takes the form (assuming that only the side-
wall contributes)

win                t    P
                rrm2    o             [tfS*J )*,    <D
                                                     p
                                                         s,t


       A
       A 'TT
                                        ,revTl
           R + 8AA'
                                       JÂ£(Â«> I
                            r<Aco

                        8AA                   rev
        ext                                              i s,t   ,   (19)
                         irm 2   C!     2^
                                      r<Ao>
        rad


where A denotes the surface area of the complete cylinder.
n is the sum of the average external radiation loss factor,
 r
       ext
i.e., n"",, and the average structural loss factors r r
       rs-d
T, is the trim transmission coefficient, and i is the resonance
 t                                            j^
transmission coefficient for the diffuse field case,




                                         23
In this expression n is the modal density of the fuselage
structure (modes/rad/sec). The summation r<Aco in Eq.(19)
implies a sum over all structural modes 03 that are resonant
below the frequency band of concern, p is the exterior air
density. The radiation loss factors are

                  *ext
                    4- =       o)A
                             oâ€” < 2          >rev.
                  rad    -rrmc                   r

and
                  Int = 2pq)A
                  rad ~ Time

            rev.
where < J 2 > is the joint acceptance averaged over the structural
modes resonant in the band.

Let Tf = field incidence transmission coefficient for mass
controlled panels as defined in [3].
                                       rev
                       32                                         (20)
                                    r<Aco

Then Eq.(19) becomes
              W                              A
               in "                                             ,,t


                             ext      R + T.         <Pl> s,t     (21)
                            n rad
The power absorbed on the wall is again given by Eq.(5). Since
at these high frequencies the response is resonant acoustic, <on
can be considered to lie in Aco and Eq.(5) reduces to


                  W diss
                            p
                                o    neAu)
Further, noting that for this case wn ~ w for any n, and letting
the group of acoustic modes have an average loss factor nn, this
reduces to
                                     2
     w          = â€”â€” 2 Lin s      <p
                                  H >  >. =   . urn <D 2 >
         diss     pc     n ^       n s,t    pc^w 'n pi s,t                     ,


which is Eq.(7), Section III of [2].                      Finally, setting




where a is the band average absorption coefficient and S the
absorbing surface area, the above reduces to the familiar form

                     W                                                             (22>
                      diss â€¢ nff^ <Pi>,.t â€¢

S includes the area A covered with trim and any other absorbing
surface area.      Equating Wln       to W diss gives the desired high
frequency result

                                        T
                     e s,t             L -fI.        11    J.   J. o.v_l   |       / â€ž _\

                                      T T A
                  ^^s.t                t        t + TA'

where T = T f + T R .

This is the fundamental result with trim present. Note that if
all transmitting surface is covered with trim, A' = 0, and

                         <p
                              e>s,t    _        aS



On the other hand, if trim does not exist, Tfc = 1, Afc = 0, and

                       2
                    <P
                     p >  4. _ aS â€¢
                      e s,t
which is the result in [3] without trim.

Finally, 5 is estimated with the relation


                           o

When trim is present nn is calculated with results developed in
Appendix A.

3.M   Calculation of the Generalized Forces for Propeller
      Noise Excitation

Consideration is now given to the various terms that appear in
the equations representing the solutions of the sound trans-
mission problem. In this particular section, the calculation of
the generalized (or modal) forces for propeller noise excitation
is discussed. Specifically, consideration here is given to the
term ^G(r,H) as defined in Eq.(lO) and that appears in Eqs.(8)
and (16).

ANOPP Computer Program Output

In the present case, the fluctuating pressure field acting on
the fuselage due to the rotation of a propeller is determined
with the NASA Langley computer program ANOPP [5].  This particu-
lar program is one of a number of such programs to exist in the
aircraft industry. It was especially developed to allow pre-
dictions of noise from propellers that have advanced blade
geometries. In the present case, the concern is more with the
standard type of general aviation propeller. The ANOPP program
easily handles the typical general aviation aircraft propeller
blade.

For purposes of the present model, the primary concern is with
the form of the output data from ANOPP. Referring to Fig. 1,



                                26
on the fuselage structure, there will be a finite number of grid
points at which the pressure time histories will be available.
At each point, the modal deflection will also be available,
say ^r(x ). Associated with each grid point is the area AA where
(Fig.l) AA = A2 with A being the grid spacing. Now in Eq.(lO)
dx is an element of area, so in discrete form (10) becomes




where


                                         = * r (z kl ,e Â£f )

and m identifies each grid point (k,Â£),k being the axial index
and I the circumferential one. In the present model, the grid
is confined to the side of the fuselage where the propeller is
located.

To compute y_ (r,H), the .form of CD, , (x 1I x .) that will result
            u                      ^bl m m' ,
from the use of the data output by ANOPP is first needed. At
each point m, there will be a pressure time history that will
repeat itself over a period TQ = BPF       as shown in Figure 1.
Naturally from point-to-point on the grid, this pressure signa-
ture will be different. Note that To is 1/B of the period T
of rotation: T = 60/N, where B is the number of propeller blades.

Now C    (x"m|x ,) is defined in terms of the pressure time
histories for the point pair (m,mr). To calculate Cp,,(x |x ,)
the equations appearing in Section 3.2 are considered in
sequence. First
                              T/2

                                                                 (25)




                                27
Since P^i^^t) and Pb-,(x , ,t) are periodic with period To,
the time average can be performed over one period, yielding


R
                                        r
    P b l ( x J V ; T > = 5^ J
                                         O


In the present case u                            (x Â»t) is real so


        R
            Pbl(xiJxm';T) = T
                                                i ^Â° b l m 'p    (x       t)p
                                                                                bl(xm"t+T)dt          â€¢ (26)

Also since p, , (x ,t) is composed of discrete frequencies, a
Fourier series representation can be used


                                        am            Â°Â°
                                                      *~^ 3â„¢
                                                           H
                                                                          1- + hm        '       1-      (?7\
                                                      H=l             H              H       H

By d e f i n i t i o n     OJ H = 2frf H = H ( 2 f r f ; L )

where        f-j^ = 1/1^              and         T   = T       = 1/BPP              ,

                                  T


                                  T
                 m
                     = 2      f1        P b l ( x m , t ) c o s a ) H t dt           ,                   (29)



                            JT.

                                                ,t) sinw u t dt                  ,                      (30)
                                            i               n




Let
             A
                 H =       ( a ) 2+ ( b ) 2                                                              (3D
and




                                                                28
Then
                                                   am

                                                                 H =l

and
                                                   am'                   -
       P bl                                                              H cos l-k> H ( t + t )
              f \r           4- J.t-   \   â€”        O        I       X   "^ A 1ft           r   / j   .   \     ITl'-i            ^ -, I x
                      m'                   ~ ~~?â€”                    /                                        -<j> ]         .   (3*0
                                                                     H=l
Substituting these into E q . ( 2 6 ) (using T                                                        = T ) gives



                                                                 :1 a
                                                                             o ao

                                                         o
                 -L / - H l v               00




                      (^^ E                              H
              /.      V 2
                            /H-1

                              / m1
                  /
                              fe


        +
              1
                      o"          H=l H'=l
                                                                                                                                  (35)

There are four terms appearing in Eq.(35). It is easy to show
that the second and third terms are identically zero. The
remaining two terms give upon setting Â£<!>â€ž     m - (J>
                                         mm' = ij>   m' ,
                                          n     n    n

                                           mm'                   â€ž           n m n m'                               _
                                                                                        \                        ,mm 'I
P      (v   Iv         -Tl        = - -â€¢ ."â€” -f-                 7       I      ^       1 COS | W U T + Acp H            I        (36)
    PblUm' m1'*                                h
                                               4
                                                          ^
                                                         H=l




                                                                                29
It can be seen that the mean.square pressure at xm is




                                 / a m\ 2         Â°Â° /.m
                                                       A \
                                                           2

                                 (~To) â€¢ *-Â»
                                         y ( ITH)
                                                 H=l    ^

                                 / m\2     Â°Â°          / m \2      . /, m \2
                                 ( a oj +
                                        . Y            (aH)        +
                                                                     (bH)
                             ~       ~                 -               -
                                             H=l

Continuing now, with Rp ,(x lx ,;T) defined, the next step is to
compute the two-sided cross spectrum using


                          = Re I â€”          | iw, tx_| x^, j-i ;e                 QT j     .    ^7)


Prom Eqs.(36) and (37), it is found that
                          a a
                                 '
    S
        Pbl(xrJxm''w) =

              ,m n m'<
                                                                                         (38)



The one-sided cross spectrum is therefore

                          mm1                                  '
                                                                               '6(^)     . (39)


Finally using c pbi( x ml x m' ;w^ = C Pbl^ x ml x m' ^ <S(CO-WH) , it follows
that




                                            30
Note that each harmonic wn corresponds to the tone frequency
in Eq.(8). To compute Eq.(8), a harmonic is first selected.
For that particular harmonic, from Eqs.(lO) and (40)


 V r > H) = T- X>S          ^m'X!


One of the things to note about this result is that all of the
information that can be garnered from the propeller noise signa-
tures is used. However, a disturbing feature of Eq.(4l) is that
for a big grid, the total number of numerical summations re-
quired can be extremely large. Since ^G(r,H) must be computed
for each structural mode, the computations could be very time
consuming. Fortunately Eq. (41) can be reduced to a more effi-
cient result using the trigonometric identity



      cosAt))â„¢"' = cosmos*â„¢' + sin<t> m sin<t> m '
             n        n   n          n       n

to yield




In Eq.(42), (2m + 1) summations are required as opposed to the
m2 summations needed using Eq.(4l).

Geometrical Considerations and Reflecting Surface Effects

The ANOPP program computes the acoustic pressure for the case
of a propeller in a free-field. Here the presence of the fuse-
lage structure needs to be taken into account since acoustic
waves will be reflected by the surface. In this model, the am-
plitudes of the various harmonics are increased in proportion to



                                    31
the incidence angle. The phases computed with the ANOPP
program are not modified. Until now the amplitudes AH in Eq.(iJ2)
have been considered to be the ANOPP results. However, hence-
forth, they shall represent the blocked pressure amplitudes. To
distinguish between the blocked amplitudes and the free field
amplitudes, the free field values from ANOPP will be redefined by
placing a bar over Aâ„¢ . The blocked amplitudes are calculated
from the free field values using




This empirically fitted curve corresponds to that found by
Magliozzi [6]. Y is the "incidence angle", that is, the angle
between a line running from the propeller hub to the point xm
on the fuselage and the normal to the surface at that point.
The angle is calculated using (refer to Figure 2):



       _, I (r cos4>-acos6) (cos9) + (r sin<J>- asin6)(sin9)
Y = cos" ' â€”P-             .             B_
            /(r cos<}>-acos6) 2 + (r sin<J> -asin8) 2 + (z - z ) 2


3.5   Interior Coupling Factor f*(ntr)


This term determines the spatial coupling occurring between a
fuselage structural mode and a cabin acoustic mode and is
defined in Section 3.1 as

                                             r
                      f Â«(n,f) = - fc}>
                                     n
                                       n(x)4> (x)dx,                 (115)
                                  A /
                                  RJ
                                     A
where x represents a point on the transmitting structure. 4>n(:
is the eigenvector for the nth cabin mode which is obtained
using a finite-difference technique as detailed in Appendix C.
i|;r(x) is the structural mode shape and its calculation for the

                                        32
present fuselage model, a cylinder with a structurally integral
floor, is considered in Appendix D.

Calculation of f*(ntr) for Cylinder with Floor

The modes of the fuselage are given by Eqs. (D.22)-(D.26) in
Appendix D. For the symmetric modes of the shell, these are
                                   n*
               <(z,6) = +sin^ D CjÂ£(-l)n cosne            (i,6)
                5             L
                                n=0
and for the antisymmetric modes



                                      n=l
 O TO

CMn are the generalized coordinates defined by Peterson [13], as
tabulated for an example case in Table D.I of Appendix D. Also
as shown in Figure 1,9 = 0 at the bottom centerline, 0 = TT at
the top centerline. ^ 5 is positive along the outward normal.

For the f l o o r ( p l a t e ) , the symmetric modes are
                                           n*
                .^ r, ( z , x )N = sinâ€”-
                                    . MTTZ
                   p



and the antisymmetric modes are
                                     n*

                                                    P
                                    n=l
where (Figure 1), x is measured from the center of the floor,
ty is positive in the upward (inward) vertical direction, and
Lp is the width of the floor plate,
                       Lp = 2a sin 9Q           .

The acoustic mode eigenvector calculated with the finite differ-
ence technique takes on discrete values on the bounding surfaces
of the cabin.     Consider the boundary point j = (m,n) of Fig.C-2.

                                       33
From Appendix C, Eq.(C.9), the nth acoustic mode evaluated at any
point Â£ in the cabin is

                                                                  *(J)                    .                 (50)

On the cabin bounding surfaces, i.e., C=x                                         the eigenvector takes
the values

                  4>n(x) = 4>qÂ±(x) = c o s . <|.1(eJ)                             t                         (51)


where $.(8.) is the same as <J>.(j) when j is a boundary point.
        -*-   J                            -L
To include trim on the sidewall (with a bare cabin floor) the
transmission coefficient T.L> is introduced with the result


                                           COS
   f'(n,r) = f'(qi,r) = Â£ f                      ^1T sln^dZ

                                 2ir-8 _
                               /â€¢2TT-8                                                    _k       /2
                         /~H /         Â° r/                                           C
                        /T   I         a\j>
                                       a. >f (v 8
                                                . v)j y<>bf ' .V( -6' /)* d
                                                             v      lvJ
                                                                          - 6 â€”
                                                                              â€”       II                '
                          tj                s           i                             /
                               9
                               Q                                                      â€¢/_

                                   O                                                           P
                                                                                                            (52)

A bar is placed over f ' ( n , r ) to indicate inclusion of sidewall
trim. Eq. ( 5 2 ) is an approximation and not an exact result. It -
should be s u f f i c i e n t l y accurate for the present needs. It is
noted that the < J > j ( 8 ) are the boundary values of the acoustic
                                                                                                            T"*
eigenvector, i.e., the same as the <j>.(6.) in Eq.(51) and fy (8)
      r                               "*"
and i|>  (x) are given by the summations  in Eqs. (46 )-(^9 ) .^ Since
4>.(6) is known only at discrete points 8 = 6., j = 1, ..., n,,
the last two integrals in Eq.(52) are approximated numerically.

Let 6-, . and 8_. define the points on the circumference of the
cabin cavity half-way between boundary point (m,n) and the two
adjacent boundary points. The eigenvector <J>.(6.)
                                             _L J
                                                   is then assumed
to apply over the range 8     to 8?.. For the shell, the second
                         -L J     ^-J
integral in Eq.(52) becomes
                n
n*              b
                                                                                    (53)



that is, if both the acoustic and structural modes are symmetric,
If both modes are antisymmetric,                         it is found that the integral
evaluates to
                        n
                            b


     n=l

The integral is zero if one mode is symmetric and the other
antisymmetric.

Next consider                           T
                                            P
                                                r

                                    L /2
                                -P
For two symmetric modes, this becomes




                        Â»
              pr    ^                               nT      mrx9,      mrx
                                                            -j-^- - sin -L^IJ       ,      (55)
                                                               P           P


and for two antisymmetric modes
                    n
                        b
                                                          mrx., .         mrx0 ,~
                            ^i  (
                                    J
                                        ;
                                     1 ' n" I         Cos
                                                            â€”^~     ~   cos                (56)
       n=l   ''"' j=l


                                                     35
The integral is zero if one mode is symmetric and the other
antisymmetric. In this case n/ is the number of boundary points
at which the acoustic mode has been computed on the floor.
Finally, let

        -P
        f qM
              â€¢if
               j.
           M = L
                    i
               T~ J /
                        Q
                         -L
                                  COS
                                        QTTZ
                                        ^T~
                                         L              L,

For the case considered (shell length L = cavity length L c ) ,


                                  l - c o s ( M + q ) T T + l-cos(M-q)Tr"|   .
                                         M+q                    M-q      J   â€¢

                    0         ;      M= q

If L ^ L , f M is given by the relations in R e f e r e n c e [3].

3.6   Joint Acceptances for Cylinder with Structurally                           Integral
      Floor

The joint acceptance function appearing in Eqs. (16), (18), (19),
etc., describes the coupling between the excitation field and the
structure, and is defined by the relation

         J 2 ( o > ) =_       l
                                          ||Spbl(x|x';a)Hr(xHr(x')dxcix' , (58)
                     ~
where A is the excited structural area, 2,^(03) is the blocked
pressure power spectral density, and S , , (x| x' ;o>) is the blocked
pressure cross power spectral density.

It has been general practice, when representing random pressure
fields with spatially decaying correlation, to use a correlation
function of the form

                                 Re(S (x|x';oi)}
                   C (x|x';&)) = - 2-                                        .        (59)
                    p



                                                   36
It is assumed in the present analysis that this function is
separable in the longitudinal and transverse directions, i.e.,

            Cp(x|x';ec) = GX (Â£ , u)Cy ( ? ,<u)
where
            Â£ = x-x' ;      Â£ = y-y'
The representation for a diffuse (reverberant) excitation field
is well known and is given by




               Cy(?,co) = S g               ,                "(60)

^where k is the acoustic wavenumber.


Consider the structural mode shapes for a freely supported
(ideal) cylinder:

                             ,    MTTZ    Jcos N 6|
                            sin
                                  â€”       (sin N e|

The joint acceptances for this simple modal system have long been
available [17]. Now for the case of the reverberant field, the
joint acceptance functions for the cylinder must consider both
sines and cosines of the circumferential wavenumber.      One can â€¢
write jj(co) = jjU)rev'= J^NU)rev' in the form




where ^ represents the cosine and <(> the sine of the wavenumber.


The joint acceptance for the axial component of the cylinder
        2 rev
modes, jM (eo)f is given by [17]:


                                  + I2(M) + I3(M)     ,         (63)




                                     37
where
                        I (M) =             J1       {Cin(kL +MTr)-Cin|MTT-kL


                                                {Si(kL
                        I (M) =                             +M7r)-Si(MTT-kL )}

                                                  M
                                        l-(-l) coskL
                         3""            (M7i)2-(kL )2

Si and Gin are the sine and cosine integrals [18].

The joint acceptances for the circumferential modes are [17],
                                               y
                                           'l~
                                           ^ _ 2)* ' c o s 2NTry 1 cos
                                         V" 1     2J

                       r~ r sin27rka(y,-y 2 )
    j 2N( u Â» 4 > ) ~ II I I   T~;â€”7
                               ^ T T kv\a / yI , - y S0 \\I sin 2NTiy,1 sin
                     Â«^    <J
                       o o                            '
                                   f
where y-^ = y/2-rra, y2 = y /2ira, y and y' being circumferential
coordinates of the two correlated points, and k the acoustic
wavenumber. It follows that
                                                               ,rev
                                                   o),^)    + Jj(u)j



           f1 f         sin2TTka(y -y )
         -\ J                                    l
            O       O                     â€¢*-    '-'


This reduces to




and
                          â€¢â€¢/  Â»'<->o
                                          sin27Tkan          ,    cos




                J
                    o'^ â€¢ f



                                                       38
where n = y-^-y^.    Performing the integration results in

                                           - Si[2ir(N-ka)] I



                                       N
and
                                    1-cos(ZTrka^)I
                                                 J'            (65)

The cylinder structural model in the present case is much more
complicated and the cylinder modes are given by Eqs. (46) and
(47) of Section 3-5. However, the joint acceptances for the
modes of the cylinder with the structurally integral floor can
almost be expressed in terms of the joint acceptances for the
simple cylinder because the mode shapes given in Eqs. (46) and
(47) are in a form similar to that of Eq.(6l), that is, they are
given in terms of sine and cosine functions. The joint accept-
                                                     9 rey
ance for the axial component of the cylinder modes, j* (co) is
thus the same as for the simple cylinder and is given by Eq.(63)j
                                  -rev
and the desired joint acceptance j* (o>) is given by

                     rev     rev      rev                      .,,.
                    jfu) = j* (oO - JÂ£_(a0        ,            < 66)

where for symmetric modes,


                    ^?X)=    f:o(cE)' JiC.,+ >        .        (67)

and for anti-symmetric modes,


                                (CÂ«n)2 J n<-*>                 (68)

Note here that N is a counter and is defined only in the sense of
the duo (r,M), that is, for each r, there is an M and a sequence
     sr*
of C     that are identified with index N.


                                  39
It is fairly straightforward to show that

                     Si(2-rrka)       l-cos(2Trka) .      n
                                  ~    2Tr2(ka)2   '
                                                                (69)
                   , I2(n) + I3(n) -            ;   n>0


and

               ,                I2(n) + I3(n)                   (70)


where

         z (n) =
          i                    Cin[2ir(n+ka)]-Cin[| 27r(n-ka)   (71)

         I2(n) =         Si[2Tr(n+ka)]-Si[2ir(n-ka)]

                           1
         T (n)
            f) =            -cÂ°s2Trka                           (73)
         I
          3 n              1_(ka/n)2



 3.7    Resonance Frequencies

The frequencies con and wr of concern pertain to cabin and struc-
tural modes respectively. The cabin resonance frequencies, cor
are determined with Eq.(C.7) or (C.ll) of Appendix C using the
eigenvalues from a two-dimensional finite difference calculation
as detailed in that appendix. The structural resonance frequen-
cies, Â«rj a^e obtained from the analysis considered in Appendix D
leading to the associated program output as shown (for an example
case) in Table D-l.

 3.8 Loss Factors

There are a number of different loss factors that must be
considered. Referring to Eqs.(8) and (18) of Sections 3.2 and
3.3, there are the lossfactorsn     ,n , n ' , and n ' ' . In
Eq.(l6), the loss factors nn and nr appear. Finally, in Eqs.(19)
                                       i n i"    ^ x 1~
and (23), there are the loss factors rirad and rirad â€¢

                                       40
3.8.1   Acoustic Loss Factors nn and nn

Bare Fuselage (Cabin)

The acoustic loss factor ^n of a bare cabin is defined herein to
be a measurement for a particular acoustic mode and n the
average   acoustic loss factor measured for a group of modes
whose resonance frequencies lie in a narrow band Aw.


Calculation of_nn, when sidewall trim is present

The calculation of the acoustic loss factor at any frequency co
has been discussed in Appendix A (resulting in Eq.(A.12)). That
result has to be formatted properly for the case where the floor
is present. Also, the absorption of the ends of the cabin has to
be considered. In cases where the sidewall and the surfaces at
each end of the cabin are covered with a trim, the loss factor
for the interior is calculated with

             n          U
                 n - ZPf" T  4>Â£dx + 2Â£j    <J>Â£                  (74)
                         Jcurved       J ,
                                         ends
                       L surface
Here E, is the sidewall conductance and r        is the conductance of
                                            e
the end surfaces. The first integral in Eq.(?4) is
             r                  n vb
             J      *n** -\ V E *j(e ) [ -e U                    ,     (75,
             â€¢'curved
               curved                 J--L
                                      J--L         L
               surface
where nb    is the number of boundary points.            The second integral
is                                n
                                      J

                      L
                      'ends   n
                                          4>2(j)h2C(j)     ,            (76)


where n. is the number of interior and boundary points.               There-
        J
fore at low frequencies, the loss factor is found to be
                                             n
                              E I,
                         we o _n I L
                                   T
                                                 b
                 nnn =
                         w2    V lr 2   q ,_-,
                          n                j ~J-
                                                              (77)

where *g(i) is the generalized mass for the two-dimensional mode
indexed i (i = 0, 1, . . . , i ' ) of Appendix C and en is the
normalization constant given by Eq.(C.lO) of that appendix.
Also e         = 2 for q = 0; 1 for q > 0.
          4.


At high frequencies, the average loss factor is used and is




S and Se being the sidewall and ends' surface areas.

In cases where the average absorption coefficient a is available
for the various frequency bands, n can be calculated with
Eq.(2U). However, in general it is a that is to be calculated
from f) and f\ is to be analytically derived using Eq.(7^) where
the conductances C and Â£ are based on the trim admittance calcu-
lations made with Eq.(A.16) of Appendix A.


3.8.2         Structural Loss Factors

The structural loss factor nr is defined as the sum of two com-.
ponents, one due to dissipation in the structure (in vacuo) and
the other due to radiation losses, i.e.,


                              nr. = nf ruc + n       .      (79)
 S t TMJ C*
n      is either a measured value or an estimate based upon
measurements for, say, similar structures. In the absence of any
actual measured data, it is recommended that one use [19]
                           struc  C
                          nr     =â€”             '                 (80)

where fr is the resonance frequency and the constant C typically
ranges between 2 and 4 .

The acoustic loss factor nr   is the external radiation loss
factor for mode r. It is calculated using
                     rad        ,
                   n            J
                     r            rwr       '               (81)
       .rev
where jr (u) is given by Eq.(66) of Section 3.6.

Influence of trim on structural damping

If trim is present on the sidewall, the loss factor il'r is given
by Eq.(A.7) of Appendix A, i.e.,            .              -

                ,  | > C w l 2 2C^r      2\
                                            h
                n                     +
                r -j-TT-
                   (m2^       - ~^
                                 mo>*   M |         . â€¢ -        (82) '

Cw is a (complex) parameter dependent on the values of the
coefficients of the trim transfer matrix and it is given by
Eq.(A.8) of Appendix A.

Influence of Internal radiation: closely coupled structural and
acoustic modes

The loss factor n^' modifies the damping level of a structural
mode when its resonance frequency lies very close to a resonance
frequency of an acoustic mode. The increased damping is due to
power flow from the structural mode to that particular highly
receptive acoustic mode. It is given by [7] " -

            n
            r' = ~^7T          â€”   T^-   , . \n2      .-r   â€¢   ' (83) "
The mode r is typically a structural mode lying within a
bandwidth Aco^ = nnÂ«n centered on o> .

Average radiation loss factors

                             ext      int
The radiation loss factors rirad and ^ra^ are given by the
relations in Section 3-3, namely


                  n ^-â€¢"â€¢"   _     O
                                         <^ â€¢ 2 / > \.reV
                   rad - ^â€”               Jr^) r
                           o

                  n int = â€”2pwA <^Ji. 2(tw)>
                                           w^ev
                   'rad          Trmco    r^ ' r
         2       rev
Again <jr1,(&)>r,    is the joint acceptance averaged over the
                â€¢"â€¢                               ,rev
structural modes resonant in the band. Each jr (o>) is calculated
with Eq.(66) of Section 3-6.

3.9   Validation Studies

Comparisons of analytical model predictions with measurements
taken in a model validation experiment are considered in
Appendix E.
                          REFERENCES

1.   Pope, L.D., and Wilby, J.P., "Band-Limited Power Plow into
     Enclosures," J.Acoust. Soc. Am., 62, 4, 906-911 (1977).

2.   Pope, L.D., and Wilby, J.F., "Band-Limited Power Plow into
     Enclosures,II," J.Acoust. Soc. Am.3 67, 3, 823-826 (1980).

3.   Pope, L.D., Rennison, B.C., Willis, C.M., and Mayes, W.H.,
     "Development and Validation of Preliminary Analytical Models
     for Aircraft Interior Noise Prediction," J- Sound and Vib.,82,
     4, 541-575 (1982).

4.   Pope, L.D., Wilby, E.G., Willis, C.M., and Mayes, W.H., .
     "Aircraft Interior Noise Models: Sidewall Trim, Stiffened
     Structures, and Cabin Acoustics with Ploor Partition,"J>Sound
     and Vib., 89, 3, 371-^17 (1983).

5.   Padula, S:.L., and Block, D.J.W., "Acoustic Prediction
     Methods for the NASA Generalized Advanced Propeller
     Analysis System (GAPAS)," AIAA Paper 84-2243, July 1934.



6.   Magliozzi, B., "Acoustic Pressures on a Prop-Pan Aircraft
     Fuselage Surface," J. Aircraft, 19, 2, 104-111 (1980).

7.   Pope, L.D., and Wilby, E.G., "Analytical Prediction of the
     Interior Noise for Cylindrical Models of Aircraft Fuselages for
     Prescribed Exterior Noise Fields. Phase II: Models for
     Sidewall Trim, Stiffened Structures, and Cabin Acoustics
     with Floor Partition," NASA CR-165869, 1982.

8.   Goldstein, M.E., Aeroacoustics, McGraw-Hill Book Co., New
     York, 1976.

9.   Ffowcs, Williams, J.E., and Hawkings, D.L., "Sound Generation
     by Turbulence and Surfaces in Arbitrary Motion," Phil. Trans.
     Hoy. Soc. London, A264 (1969).


                             -45-
10.   Farassat, F., "Linear Acoustic Formulas for Calculation of
      Rotating Blade Noise," 41"^ Journal, 19, 9, 1122-1130 (1981).

11.   Woan, C.J., and Gregorek, G.M., "The Exact Numerical Calcula-
      tion of Propeller Noise," AIAA Paper 78-1122 (1978).

12.   Farassat, P., and Succi, G.P., "The Prediction of Helicopter
      Rotor Discrete Frequency Noise," VERTICA, Vol.7, No.4,
      pp. 309-320, 1983.

13.   Peterson, M.R., "A Study of the Effects of'a Longitudinal
      Interior Plate on the Free Vibrations of Circular Cylindrical
      Shells," Ph.D. Thesis, Oklahoma State University (1973).

14.   Peterson, M.R., and Boyd, D.E., "Free Vibrations of Circular
      Cylinders with Longitudinal, Interior Partitions," J. Sound
      and Vib., 60, 1, 45-62 (1978).

15.   Mikulas, M.M. Jr., and McElman, J.A., "On Free Vibrations of
      Eccentrically Stiffened Cylindrical Shells and Flat Plates,"
      NASA TN D-3010 (1965).

16.   Leissa, A.W., "Vibration of Shells," NASA SP-288, 1973.

17.   Cockburn, J.A., and Jolly, A.C., "Structural-Acoustic
      Response, Noise Transmission Losses and Interior Noise Levels
      of an Aircraft Fuselage Excited by Random Pressure Fields,"
      AFFDL-TR-68-2, 1968.

18.   Abramowltz, M., and Stegun, I.A., Hdbk of Math.Functions,
      U.S. Dept. of Commerce, Nat'1 Bureau of Standards, Amer.Math.
      Series 55. Washington: Govt.Printing Office, 1964.

19.   Anon., "Damping in Acoustically Excited Structures," Engineer-
      ing Sciences Data Unit Item No. 73011, ESDU International Ltd.
      (1973).



                              -46-
20.   Wilby, J.P., and Scharton, T.D., "Acoustic Transmission
      through a Fuselage Sidewall," NASA CR-132602, 1975.

21.   Schultz, T.J., "Wrappings, Enclosures and Duct Linings,"
      Chapter 15 in Noise and Vibration Control, L.L. Beranek,
      Editor, McGraw-Hill, New York, 1971.




                             -47-
                   APPENDIX A

SIDEWALL TRIM: TRANSMISSION AND ABSORPTION MODELS
                 APPENDIX A - SIDEWALL TRIM



Transmission

In Section 3, the basic power flow and dissipation expressions
used to solve the sound transmission problems are presented.
The relations include a transmission coefficient T and a
                                                  tv

structural loss factor n^, that appear once fuselage sidewall
trim is assumed to be present. In this appendix, the analyses
that lead to these terms are briefly reviewed.   Most of this
material can be found in greater detail in the Phase II report,
Ref.[7]. As stated in [?], to incorporate the effects of side-
wall trim in the transmission analysis, the interactions of the
exterior pressure field, fuselage structure, insulation and
lining, and interior field must be considered. To integrate the
trim dynamics into the analysis, the basic expressions that
describe the response, transmission, and absorption characteris-
tics of the various components of the sidewall system must be
considered. To this end, the trim is assumed to be represent-
able by a transfer matrix:



                 I   w2
                          La21
                                 a
                                  12

                                       w1
                                                           (A.I)



where referring to Figure A-l: w-^ is the displacement of the
fuselage skin at x, p^ is the pressure on the inner surface of
the skin at x, wd0 is the displacement of the trim panel at x,
     i
and P2 is the pressure on the trim inside surface at x (cavity
side). Reference [7] should be consulted for more discussion of
this trim model.

In addition to the trim equations there is the basic expression
for the response of the sidewall. For harmonic excitation it
is



                                 A-l
Exterior                            Interior (Cabin)




            Skin
                t        T
                        Lining
                Insulation




  FIGURE A-1.    A BASIC SIDEWALL TRIM
                INSULATION AND LINING




                        A-2
           w-^x) = /G(x|x';co)[pÂ°(x') - p^(x')] dx'         ,   (A.2)

where G(x|x~';co) is the structure's Green's function, and pÂ°(x"')
is the exciting exterior pressure field. The integral is per-
formed over the excited structural area.


Also, the interior acoustic field acting on the trim lining is

          P ^ C x 1 ) = - pco2J"Gp(x|x';u) w2(x)   dx   ,       (A.3)


where Gp(x|x';w) is the Green's function for the cavity and p is
the density in the cabin.


Finally, the exterior field is


        pÂ°(x') = Pbl(x') + pou)2 j" GÂ°(x|x' ;w)w1(x)dx


                = pbl(x') + pr(x')       ,                      (A.4)

PQ is the exterior air density,
GÂ°(x|x';co) is the exterior space Green's function,
pr(x') is the radiated pressure field on the exterior surface,
Pb-,(x') is the blocked pressure field on the exterior surface.


Equations (A.2-), (A.3) and (A.^0 and the trim transfer matrix
(A.I) form a system of five equations in five unknowns: p-^, p2,
W]_, W2, and pr (or pÂ°) ; the blocked pressure field is assumed to
be determinable once the geometry of the structure is fixed and
the excitation defined.     The solution of this system of equa-
tions determines the effects introduced by the presence of the
trim. Note that if the trim is removed p^ = p* and w = w
reducing Eqs.(A.2), (A.3), and (A.4) to the set solved in
References [1] and [2].




                                   A-3
In Reference [7] it is shown that the trim panel displacement is
very nearly given by the result

                      w2(x) * CWWl(x)                          ,        (A.5)

where Cw = a~;r and a.... comes from- the trim transfer matrix. The
acoustic power radiated into the cabin is computed with the
theory presented in Ref.[l] and [2], and it is shown in Ref.[7]
that the inflowing power is given by Eq.(6) of Section 3.1 of
this report, where Cw appears in the form of its magnitude
squared,- which is defined to be


                 T,t> = |CW|2 = |ail
                                  -L -*-
                                         |-2                            (A- 6 )

Since this term multiplies a power flow expression that basical-
ly remains the same whether trim is present or not, |CWI is
easily interpreted as a transmission coefficient for the trim.

It is also found that when trim is present, the structural loss
factor nr is augmented. Thus if nr is defined to be that due to
dissipation in the structure when trim is absent and r\^ is the
total structural loss factor when trim is "present, then accord-
ing to the analysis in [7]

                                    _               + n2               (A.7)
                  r    m 2 coiÂ»         m    co 2          r
                                r               r
whe-re

                       C
                        w - cw + 1 C*                  .

and is obtained from the remaining three elements of the trim
transfer matrix from the result


                           C
                               w = l+aa                            â€¢   (A-8)


                                        A-
Trim Transfer Matrix

The transfer matrix for a layer of insulation is the following
(Appendix A of Ref.[7]):

                                      C       -WS 1
                                      _s cC                      (A.9)
                                        W


where   C = cosh YL ; S = sinh YL     ; Y = a-ik = a -i2Tr/Am
Y is the propagation constant of the insulation (complex). W is
the wave impedance of the insulation (refer to Fig.A.2). It is
noted here that Eq.(A.9) is not in the form of Eq.(A.l). The
matrix of concern, given in Eq.(A.l) relates pressures and
displacements, rather than pressures and velocities. Since

                                          v. =      -icow.   ,

E q . ( A . 9 ) is more properly w r i t t e n as

                                          +icoWS
                                               cÂ°                (A.10)
                                L coW

In the case where the trim is nothing more than a layer of in-
sulation, the trim transfer matrix would be given by Eq.(A.lO).

If there is a lining consisting of a limp mass, the transfer
matrix across it is the following:
                       , 2 â€ž,    j_ 3 , 2,
         P.       1    to mt +ioo z ri+_nV
                                      t i/

                  0                       1                      (A.11)


where the index 2 is the output terminal of the four-pole and 1
is the input. mt is the mass per unit of area of the lining and
r). is some assumed loss factor that arises because of flexure of



                                                A-5
    m ot
    (ml WB/m) (degrees)
     (.2 600



     1.O 500       50




    0.8    400     40




    0 6 300        30



    0.4.   200     20-    400




    0.2    100-    10-    200



     0J      0J     0J     0
                            31.5   63   125    250   500   1.000 2.000 4,000 8.000
                                        Frequency (Hz)




FIGURE A-2.             ACOUSTICAL PROPERTIES OF OWENS-CORNING
                        PF-105 FIBERGLAS: DENSITY 9.6 kg/m 3
                        (0.6 Ib/ft 3 ), [21].




                                              A-6
the lining (the stiffness being ignored).                                                      For a multielement
trim the transfer matrix across all elements of the trim is

P2                  "alla!2" " a ll a !2~                              ~ a li a i2~       ~allai2~
         \. =
                                                                â€¢ *â€¢

W
    2>              a       a
                    . 2l 22. - 2l 22.       a        a
                                                                       . a 2l a 22.       . a 2l a 22.
                                                                                                         w.
                                    n                           n-1                   2
                                                                            iv

                                        =
                                                         ^
                                                         a     3
                                                             ll a !2

                                                     , a 21 S 22_
                                                                       {"ll
                                                                           n i
                                                                            1
                                                                             }
                                                                                                              (A.12)



where           i       is trim element in contact with the skin and n is the
finishing element in the cabin.                                              The transfer matrix for the
trim of Figure C-l can be determined using Eqs. (A.10), (A.11),
and (A.12)


          â€¢I                                                                                                   i
                                                                                                                   â€¢   (A.13)
         iW,                     IS
                                "fiÂ»W                                   C                                     w.


According to the definition of the trim transmission coeffi-
cient, see Eq.(A.6), for this case
                                                                       -2
                                                T
                                                    t =
where


                        n = (c
                        a                                                                                              (A.



Note that C, S, and W are complex.


Eq. (A.12) can be used to as high a frequency as is found
(through experimental comparison) to be valid. In practi-
cal trims, the mechanical vibration transmission from fuselage
skin to trim panel will become significant at high frequencies
and eventually the errors involved with (A.I) may require that



                                                                       A-7
some alternate approach be considered to obtain the correct
input data for the trim. Because of the result in Eq.(A.5) one
can always take the ratio of say the measured mean square dis-
placements (or velocities or accelerations) of the fuselage skin
and the trim panel, average the results over the transmitting
                         W 2
surface and estimate |C'
                          |- (and thus T.).
                                         v
                                             Also by measuring the
actual damping of the fuselage wall with trim installed, n^ can
be determined and basically all of the pertinent information
required from the terms of the trim transfer matrix is obtained.
This ..allows a fairly elementary approach to the use of any
available experimental data or of any analyses that have focused
on the vibration transmission (or shorting) problem.

Sound Absorption

In addition to the transmission and damping effects, the trim
installation, will be a sound absorbing system, that is, it will
take energy from the cabin .space. It is shown in [7] that this
absorption capability is also deseribable from the terms of the
trim transfer matrix. In fact, the loss factors for the cabin
acoustic modes can be determined with the relation
                     coc  e  f
                  =
                 n ^     -T /                             (A. 15).
                     n

where Â£(x) is the conductance looking from the cabin into the
sidewall treatment. For a case where Â£ is independent of x, we
can use

                     5 = Re[6]

where 3 is the admittance given by [7]

                          -032a21Z1 +
                           <
                           iÂ«a   7 +
                                 Z  a. a             â€¢     .(A.16)
                              11    1      12




                              A-8
It is seen that the transfer matrix (A.I) describes the trim
absorption, except for the presence of the term Z,' which is the
structural impedance. In [7], a simple model

                         z
                         l = poco-lam     '                ('A. 17)

is recommended, and this is used in the present program.

Vibration Transmission to Trim

As stated previously, the mechanical vibration from fusel-a-ge
skin to trim panel can become significant at high frequencies.
According to the results found in Ref.[7] and summarized by Eqs.
(A. 5) and (A. 6), the trim transmission coefficient T, is simply
                                      <wi>
                     ,   =    cw2   = â€” L.    f            (A



that is, it is the ratio of the mean square trim panel displace-
ment upon the mean square skin displacement. As long as trans-
mission through the insulation is dominant, T^ = I a-^-jJâ€” P ; but
once the mechanical vibration transmission is dominant, <w*>
will be larger than that estimated with Eq. (A. 6) and instead,
<Wp>/<wj*> must be a measurement or an analytical prediction for
the mechanical vibration transmission. At high frequencies, a
simple expression for this ratio can be derived using statisti-
cal energy analysis procedures. The transmission coefficient
for the mechanical path is [20]:
                 m _ mtAtnt         "21                     .
                              '

where m^. is the trim lining mass per unit area, At is the trim
area and n b ' the trim modal density, m, A, -and nJ/ are the same
quantities for the fuselage sidewall. nt is the trim loss factor
(in flexure) and n?, is a coupling loss factor for transmission
from trim to skin.



                              A-9
For N point connections between skin (frames) and trim [20]:

                n                  ;htCty"""&/X"'t"t>'t/            (A.20)
                n
                    21


where h       and c       are the trim lining's mass per unit area and
          U          t/
dilatational (longitudinal) wavespeed; *h and c. are the
corresponding skin properties. For a line support, the coupling
loss factor per unit length is [20]


                                    hc        (mh%C
                      /2\%     1         *          ?)(mtht%Ct%)   ,. â€ž.
                 ~ \m / ATt                           ,.   H c 2
                                                    Cp + m,h

It is emphasized here that the finding in Ref.[7], namely
Eq.(A.5), forms the theoretical basis and justification for this
approach to trim transmission. Using these results, it can be
stated that for any trim, the T to be used in Eqs. (8), (16), (18
                                               U
and (23) is given by

                           T
                             t = ' a lli~ 2 + Tt      '            (A. 22)




                                             A-10
             APPENDIX B

FUNDAMENTALS OF PROPELLER NOISE THEORY
                  APPENDIX B - PROPELLER NOISE



The goal here is to develop the basic equation used for
propeller noise prediction in the ANOPP program. There is no
attempt to discuss its mechanization, although appropriate
references for further study are included. Consideration is
limited to propellers with subsonic tip speeds and to the thick-
ness and lifting noise components of the sound generation.

As stated earlier, there is always a problem determining just
what level to begin a technical presentation when there are a
number of different disciplines involved. In this particular
case, since propeller noise is not an easy subject to under-
stand, the authors have taken what might be considered the path
of least resistance by utilizing a result by Goldstein that has
been described as the fundamental equation of sound generation
in the presence of solid boundaries [Eq.(3.6) of Ref.8], namely




        p1
                  "kl I -oo   V



             t+
                                  o>    fyT



             t+
                                   9G
                                  8t
                                       o




                                  B-l
In Eq.(B.l), p'(r,t) is the fluctuating fluid density at the
observer location "r at time t. The equation applies to any
region V (tQ) which is bounded by surface S0(tQ) in arbitrary
motion. S (t ) can be an inner bound as in the case of a
propeller blade. There are three terms in (B.I). The first
involves Lighthill's stress tensor T. . . This term ultimately
leads to sound of the quadrupole type being radiation emitted
from the volume of fluid around the blade and is important only
when the tip speeds are in the transonic region. The remaining
two terms are the lifting and displacement noise components
respectively. p-po is the difference between the pressure on
the blade and the ambient pressure, n^ is the ith component of
                                       o
the unit normal to the blade surface, V. is the ith component of
the blade surface velocity, and G is the free space Green's
function.


            G(?0,to)|r,t) =            6(to-t + R/co)     (B.2)


Here r is the source location and R is the distance between
source and receiver locations

                      R = i?-?oj = |x-y| .

Note that the normal gradient is
                     9      ._ '   9


where y^ is the ith source coordinate and a sum over the index i
is implied. The normal surface velocity is

                      V     = n.V? = n-V s
                          n i l                '



where n is the unit normal vector.




                                   B-2
One reason for beginning with this result, is that it is de-
veloped carefully, unambiguously, and ingeniously by Goldstein
[8],  A reader can easily wade through the algebra that leads to
Eq.(B.l). The remainder of this appendix is concerned with the
manipulation of this result to obtain the ANOPP equation, what
shall be called here as the propeller noise formula.

To begin, it is noted that the relation between the fluid den-
sity fluctuation and the fluid pressure fluctuation, (neglecting
heat conduction in the fluid) is simply

                       p' =â€¢ c * p '


For convenience, the prime on the p is dropped on the left hand
side, and on the right hand side, we replace the airfoil pres-
sure (p-p0) by I. Now p is understood to be the fluctuating
pressure and it follows that Eq.(B.l) can be rewritten as

              ri+ r                     f 6(t -t + R/c ) I
 ^p(r.t) = J     J       -nÂ±a 3|- [ â€”-2         g    2_ JdS Q dt o




                              3 i(t -t R/c
          *+ Jr Jr       Vo i â€”0 fL Â° *s Â°'1 J|ds dt
                            svv                               o      o


                                                                         (B.3)


In the above R is independent of time,

Consider first the evaluation of


                      6(t -t + R/c )
                         o
                             R
                                  ~
                                        ^]-
                                  B-3
                                              R/C
                                                  o'     - TT 3?I I^V* + R/Co>]



Now
                             = nn
                                    i R* 9y
                                              i               R;


                                  n â€¢ (r-r )            n â€¢G
                                       R3                R2
        /v

where ur is the so-called unit radiation vector
                                     r_r




Also
                  __        _                 _
             R ay.                          o ) --~^.PÂ±L
                                                  -R- 3T
where        T = t -t + R/c
                  o         o

             9T        J^ 9R = "(xi"yi) ^ "^
             3y-i      c o 9y.i        c oR             co
and

             36(T) i
              9T            dT

Note that

                       36(T) _ 36(t) 9T = d6(i)
                        3t   ~ 9i    9t     di
                           o            o

This latter result follows because R is independent of to,




                                                  B-4
Following the general approach used in propeller noise predic-
tion, it is now convenient to introduce a Lagrangian coordinate
system (so-called n system [9,10]) that rides in the body and in
which S0(tQ) remains fixed (see Figure B-l).

The velocity V and acceleration a of any point ri in this coordi-
nate system is
                             3?
                         V = *tT ^'Vfi - fixed
                             3V     /-        x
                    .                    -n       = fixed   â€¢ *

Since S0(t0) = So is fixed in this system, i.e., SQ               is a rigid
surface: every point has velocity


                           V = V
                                   o(to)


where V is the velocity of the origin of the n system and w is
the angular velocity of S (or the n system). Since n and y are
Cartesian, the Jacobian of this transformation, i.e.,


                              ( rQor y}-> n             -

is unity.

In the n system, the limits of integration of the surface inte-
grals are independent of t and the order of integration in
Eq.(B.3) can be reversed to yield
           f       (** n-G *
    r,t) = I          - -jrs*- Â«(t0-t + R/co^dtodSo(n)
            Jc!   Jâ€”OD


                r r r" ~                      * r;s.
             IT I I \~^



                                         B-5
 Receiver
                                                  moving




FIGURE B-1.   LACRANCIAN COORDINATE (??) SYSTEM




                          B-6
where now R is a function of time, i.e.,


                   y = r0 =        n = n                * ?0(tQ) ,

arid

                   R =   r-r                    -5(t0)|
To evaluate the integrals in (B.^) the following identities from
generalized function theory are used [9]

          r Â°Â°                     x-* f (T1)
          /   f(T)6[g(T)]dT    =   2^           ~          '          (B.5)

                                           dT       e
                                                e

where T   is the ith root of g C t ) = 0

Also



                                                                      (B.6)


The first identity (B.5) is used on the first term in (B.4) to
obtain

          f(t0)          R
                                                          - t + R/C

and

          ^K =           r dt
                           TT~ = 1 +
                          O r,



                 = 1 -




                                    B-7
Therefore,

                 OO     /^   /^
             â€¢         - n - u J,                               n* u i
                                                                    r
                                                                                       (B.7)
                                                                             W


where t oe = t-R/c0. .


The second identity (B.6) is used on the second term in (B.4)
and then the first identity (B.5) is applied to-further reduce
the second term. Using


                         f(t o) = | [n â€¢ u


gives
                      T n-u Si + p c        n-V "1 a
        /
                       _^_^_                     ^<[t^+ H/co]               at.
                  U                            1
        â€” 00                                  -




    . -/â€¢"/_Â»_ f_^v (^
        1             K             l^ri2 I
                                                                â€¢TT ^ Â«

                                                                          i5(to-t + R/co)dt0



Since   l-Mr = |l-MrJ                  for M <1, the above


                                                     n-Vk
                                      n-u r Â£ + p oc o
                                                                6(t -t + R/c )dt-
                                  o       R|l-M
                                           i      I                Â°        o o
                                                r i




Now using (B.5), setting

                                               n*u
                                               *  *
                                                      i + p c n*V
                                                               * â€” Â£

                                                    r      oo
                                                      R|l-Mr|



                                                   B-3
gives the above


                  1    3      n*u r Â£ + p 0 c 0 n â€¢Vs "
            11 I-M   1 at          R 1-M |                                           (B.8)
                   r '    o             r'
                                                              t = t-R/c
                                                               o        o

Substituting (B.7) and (B.8) into (B.I) gives, after changing
the sign so that the normal points out of the blade.


                                           p C V
   4Trp(r,t) = â€”   f I  i     L            o o n
                                                                          dSo(n)
               Â°o J  \\I-H I 3t                       R|l-M
                                                                          t-R/c.




                                                                                     (B.9)
                     R2|l-M




Eq.(B.9) can be written in an alternative form which is faster
to execute on a computer and more accurate [12]. First, the
acoustic pressure is separated into loading, pLiT(r,t) and thick-
ness PT(r,t) contributions, such that

             p(r,t) = pL(r,t) + pT(r,t)                       - .- -

Then the two components can be written in the forms
                                           _   TV/I       _   T\ff 2
                     poVn (RM.u^n
                                                                                dS0(n)
                              R2(l-Mr)3                                t-R/c,
                                                                                  (B.10)




                                     B-9
and
                                      iu *n
  4Trp T ( r , t )   =                  r
                                                               dSQ(n)
                                      R(l-Mr)2
                                                   4-   ID /




                                    u -n - Â£M.'

                             Lo
                                     R2(1-M )2
                                                   t-R/f
                                                               dS0(n)



                                      â€¢ n ( R Mi. u r â€¢n + c oMr - coM 2 )
                                                                                     dS0(n:
                                              R2(l-Mr)3
                                                                             t-R/

                                                                                    'B.ll

Mach number terms M. and M2 are given by

                                      and          = V
                     M
                     i = Vi/co                          iVi/co2

where V. =
           1
                             (u Â« n ) . Furthermore, the dot on M. and
                         O

denotes the rate of variation of these parameters with respect
to time t .
         o

Equations (B.10) and (B.ll) have been coded at NASA Langley for
use in ANOPP. The reader should consult references such as [11]
and [12] for details concerning the mechanization of these
results. Also, an alternative derivation of the present results
is provided by Farassat in References [10] and [12].




                                            B-10
    APPENDIX C

CABIN ACOUSTIC MODES
             APPENDIX C - CABIN ACOUSTIC MODES



The acoustic modal characteristics of the cabin are defined by
the mode shapes 4> (Â£), Â£ being an interior point, resonance fre-
quencies <i> , and the mode normalization given by the constant
e . In the present case, consideration must be given to the
determination of these quantities for the case of a cylinder
with a floor partition defined by the angle 6Q as shown in
Figure C-l. In the ideal complete cylinder the modal properties
can be determined in closed form by an analytical solution of
the wave equation, subject to the appropriate boundary condi-
tions. This is possible because the wave equation is separable
in cylindrical coordinates and the boundary conditions can be
expressed in these coordinates. When the floor is present, it
is no longer possible to derive the mode shapes analytically
since the boundary conditions are irregular. Thus it is neces-
sary to resort to numerical methods. There are two possibili-
ties, either finite differences or finite elements. Since in
the present case, the modal characteristics in the axial direc-
tion are known, a two-dimensional problem remains, and the
finite difference technique, which is the simpler of the two, is
chosen. First, the two-dimensional problem is solved. Then the
axial modal information is factored in. Next the normalization
of the data is defined.


Finite Difference in Two Dimensions


In the cavity (cabin), the Helmholtz equation applies.     In the
two-dimensional problem, using central differences, it is found
that for the grid of Figure C-2, the pressure P obeys the relation

     4 P
       m,n~Pm+l,n~Pm-l,n~Prn,n+l~Pm,n-l = k2.h   P
                                                 m,n   >    (C.I)

where h is the grid spacing, and k = w/c0.



                               C-l
                              4      Fuselage




FIGURE C-1.   CABIN ACOUSTIC SPACE




                 C-2
                               (m,n) = (NX,NY)




FIGURE C-2.   FINITE DIFFERENCE GRID NOMENCLATURE




                      C-3
Boundary Conditions


The boundary condition is that the outward normal gradient is
zero (the wall admittance 6 is assumed to be sufficiently small
to allow this assumption).     Thus, referring to Figure C-2, in
the region 60<9<2ir-6o:


      ^m.n+l-Vn-l* Cos9mn = (Pm+l ,rTPm-l ,n} sin6mn       '   (C-2)

If -60<e<90, the boundary condition is obtained from Eq.(C.2) by
simply setting Smn = 0 whenever e mn < e0 â€¢

Solution


Let the column vector Pj = ^Pj^n-jxl be tne pressure at interior
and boundary points. Also let PP = fPF^        be the pressure at
                                 &      & nexl
the. exterior points, adjacent to boundary points only. Using
the recurrence relationship for a'll interior and boundary
points, i.e., Eq.(C.l), gives (in. matrix notation, with
X = k2h2).

                               + R
                          Vl      EPE = XPI        >        (C.3)

where Rj has dimensions n.j xn.- and Rg has dimensions n-xn e ,
where n,- is the number of interior and boundary points and ng is
the number of exterior points.       The matrices Rj and RE will be
different for symmetric and antisymmetric modes.


The boundary conditions (Eq.(C.2)) give (ne-2) equations..      The
tangential gradient is assumed zero at two boundary points close
to 6 = TT/II and 3'n/^, giving n equations. .When combined, these
â€¢take the: form


                            BJ.TP_L
                                 T + B...P., = 0
                                       t I!
where Bj has dimensions nexnj and Be has dimensions nexne.

Since the matrix BE is non-singular

                     P
                      E = -BEVl '                            (C 5)
                                                              '

Substituting this gives




The eigenvalues and eigenvectors are calculated for symmetric
and antisymmetric modes, separately. The modes are then com-
bined, and ranked in ascending order of frequency and the first
20 modes only are used. The vector F corresponding to A . is
the mode shape (<J>1(J)), where i is the 2-D mode counter, and j
defines the position in the fuselage cross section. The nodes,
n. , represent only half the cylinder (i.e., X > 0). -The values
of the eigenvectors (on the boundary) will differ for symmetric
and antisymmetric' modes for X < 0. For symmetric modes, :
4Â»1(J) = 4>Â±(X,Y),

                           4>i(X,Y) =

For antisymmetric modes,




Each mode must- therefore be identified as symmetric or anti-
symmetric when the boundary values of the' eigenvectors are used.
Apart from the boundary values of the eigenvectors, there is no
need s to distinguish between symmetric and antisymmetric modes in
the cylinder response program. In addition, it should be noted
that the first symmetric mode represents uniform translation with
zero frequency.




                                C-5
The eigenvalues, ^, are used to calculate the resonance
frequencies for the (three dimensional) cabin with


                 fn - f_, = *Â§im    + vÂ£ \     ,               (C.7)

where h is the grid spacing ( =Ga), and L and a are the cylinder
length and radius respectively. The frequencies output by the
program are

                                                               (c 8)
                                                                -
i.e., the frequencies for q = 0 modes and. a = 1 meter.

Normalization

The acoustic modes <|>n for the three dimensional cabin are


                                                    1(j)   ,   (c>9)




where <j>.(X,Y) is the eigenvector for the two-dimensional mode
ranked i (i = 0,1,2,...) as calculated with the finite differ-
ence technique; i.e., <j>.(X,Y) is a finite dimension column
vector, which contains the values of 4>4 at all coordinate
positions j within and on the boundary of the cabin space. The
normalization of the modes is arbitrary. The maximum value
achieved at any coordinate positon has been chosen to be unity
and the other values adjusted to retain the computed ratios from
point-to-point. The normalization is carried into the trans-
mission prediction with the parameter e . In the case where the
floor is present the integral required to determine -e is



            /â€¢
                              C-6
where j counts over all interior locations. C(j) = 1 for
boundary points and centerline locations, C(j) = 2 for interior
points. Also e = 2 for q = 0; 1 for q > 0. The generalized
mass for mode i as defined in the finite difference program with
unit radius is

                     V1)     =
                                   IL <f>i(J)G2C(j)     .          (C.10)

The volume enclosed is
                   V = a2L |iT-8
                           I    o + cos8 o sine o 1
Thus
                                   2L
                                    hr-eUo + cos6 Uosine U-l
                                                         oj
                 e n _= _eqi. _-    U
                                           Â« /.\          â€”    â€¢   (n  -i -i \
                                                                   (,0.11;.

Sample Results

Figure C-3 shows examples of the finite difference calculation
for a case where the floor 6 is 56.6Â°. The first twenty modes are
shown and are ranked according to the A.. The resonance fre-
quencies are for a = 1 meter. The 1 meter results given in
Figure C.3 are simply the f. in Eq.(C.8). The resonance fre-
quencies for arbitrary radius a (in meters) is obtained from
Eq.(C.7).   Eq.(C.7) can also be written in the form
                                    c         \
                  fn = fqi         â€”^
                                   2-n   ( 2JL\
                                            L
                                              )   \co
                                                                   (C.12)

where fj_ is the 1 meter result. Note that for q = 0,
                               f.
                         f   = -i-
                         ^i      a .  '
Table C-l gives the computed generalized masses, $_(i) for the
1 meter (unit) radius.




                                     C-7
     MODE 0. SYMMETRIC                                   MODE 1. ANTISYMMETRIC                 MODE 2. SYMMETRIC
     FREQ. = 0.00                                        FREQ. = 99.5                          FREQ. = 120.4




      1.0   1.0   1.0                                    -.0   .1   .1                         1.0   1.0    .9

      1.0   1.0   1.0   1.0   1.0                        -.0   .2   .3   .5   .6               1.0    .9    .9    .8    .7

      1.0   1.0   1.0   1.0   1.0   1.0                   .0   .2   .4   .Â»   .7   .8           .8    .8    .8    .7    .6    .Â»

      1.0   1.0   1.0   1.0   1.0   1.0                                                         .7    .6    .6    .Â»    .4    .3
                                                          .0   .2   .4   .6   .7   .6
o
i                                                                                               .4    .4    .4    .3    .3    .2    .1
CO    1.0   1.0   1.0   1.0   1.0   1.0   1.0             .0   .2   .}   .6   .8   .9    .9

      1.0   1.0   1.0   1.0   1.0   1.0   1.0                                                   .2    .2    .1    .1    .0 -.0     -.1
                                                          â€¢0   .2   .5   .7   .8    .9   1.0

      1.0   1.0   1.0   1.0   1.0   1.0   1.0                                                  -.1 -.1 -.1 -.1 -.2 -.2 -.2
                                                         -.0   .3   .Â»   .7   .9   .9 1.0

      1.0   1.0   1.0   1.0   1.0   1.0   1.0                                                  -.3   -.3   -.3   -.4   -.4   -.4   -.4
                                                         -.0   .1   .Â»   .7   .9   1.0 1.0

      1.0   1.0   1.0   1.0   1.0   1.0   1.0                                                  -.Â»   -.5   -.Â»   -.Â»   -.5   -.Â»   -.Â»
                                                         -.0   .3   .5   .7   .9   1.0 1.0

      1.0   1.0   1.0   1.0   1.0   1.0   1.0                                                  -.6   -.6   -.6   -.6   -.6   -.6   -.6
                                                         -.0   .3   .$   .7   .9   1.0 1.0

      1.0   1.0   1.0   1.0   1.0   1.0                                                        -.7   -.7   -.7   -.7   -.7   -.7
                                                         -.0   .3   .Â»   .7   .4   .9




                                           FIGURE C-3.   ACOUSTIC MODES FOR A CASE WHERE
                                                         0 = 56.6Â°, q = 0, a = 1 rrieter
     MODE 3. ANTISYMMETRIC                               MODE 4. SYMMETRIC                        MODE 5. SYMMETRIC
     FREQ. = 175.9                                       FREQ. = 187.9                            FREQ. = 220.4




     -â€¢0    .3    .6
                                                                                                  1.0      .9    .7
                                                          .6   .6   .4

     -.0    .4    .7         .9   1.0                                                              â€¢9      â€¢&    Â«6    *3    *0
                                                          .6   .3   .3    .1   -.2

      â€¢0    .4    .7         .9   1.0   1.0                                                        .Â»      .Â»    .3    .1   -.1   -.3
                                                          .Â»   .4   .2   -.1   -.4   -.6

      â€¢0    *j    â€¢    fr    *S    Â«9   Â«S                                                        .1       .1 -.0     -.2   -.3   -.4
                                                          .5   .4   .1   -.2   -.5   -.T
o    -â€¢0    .2    .Â»         .6    .7    .6    .6
i                                                         .4   .3   .1   -.3   -.6   -.9   -1.0
                                                                                                  -.3   -.3     -.3   -.4   -.4   -.4   -.Â«
VD
     -.0    .1    .3         .3    .4    .3    .3                                                 -.6   -.5     -.5   -.4   -.4   -.3   -.3
                                                          .5   .4   .1   -.3   -.6   -.9   -1.0

      â€¢0    .0    .0         .0    .0    .0   -.0                                                 -.6   -.6     -.Â»   -.3   -.2   -.1   -.0
                                                          .6   ,5   .2   -.2   -.6   -.9   -1.0

      .0   -.1   -.2        -.3   -.3   -.3   -.3                                                 -.Â»   -.Â»     -.3   -.1    .1    .3   .3
                                                          .7   .6   .3   -.1   -.5   -.7   -.8
     -.0   -.2   -.4        -.5   -.6   -.6   -.fc
                                                                                                  -.3   .-.3    -.1   .2    .Â»    .6    .6
                                                          .8   .7   .Â»    .1   -.3   -.6   -.7

      .0   -.2   -.5    -.7       -.8   -.8   -.8                                                 -.2   -.1      .1    .4    .7    .8    .8
                                                         1.0   .9   .6    .2   -<2 -.4     -.5

      .0   -.3   -.5    -.7       -.8   -.9                                                       -.1   -.O      .2    .Â»    .8    .9
                                                         1.0   .9   .6   .2    -.1   -.3




                                                     FIGURE C-3.         CONTINUED
    MODE 6. ANTISYMMETRIC                          MODE 7.  SYMMETRIC                         MODE 8. ANTISYMMETRIC
    FRE. = 253.2                                   FREQ. = 259.2                              FREQ.= 289.7




     .0   -.*    -.9                                -.2   -.1    .1                           -.0    .3    .5


     .0   -.5    -.9   -.9   -.8                    -.3   -.1    .2    .5   .9                 .0    .3    .5    .Â«    .3


    -.0   -.*    -.8   -.8   -.Â»   -.1              -.4   -.2    .1    .6    .9   1.0          .0    .2    .3    .4    .4   .3


    -.0   -.3    -.5   -.4   -.1    .2              -.6   -.5   -.1    .4    .7    .8          .0   -.0   -.0    .0    .1   .1

o                                                                                              .0   -.3   -.4   -.3   -.1   .0   .1
I   -.0   -.2    -.2   -.1    .3    .6   .8         -.8   -.6   -.3    .1    .5    .6   .5

     .0   -.1    -.1    .2    .*    .8 1.0          -.8   -.7   -.Â»   -.1    .1    .2   .2    -.0   -,i   -.7   -.6   -.3   .0   .2


     .0   -.1    -.0    .2    .S    .8   .4         -.6   -.5   -.4   -.3   -.1   -.1   -.1   -.0   -.6   -.Â«   -.7   -.2   .2   .4


     .0   -.1    -.1   -.0    .3    .5   .7         -.1   -.1   -.2   -.2   -.3   -.3   -.3   -.0   -.6   -.8   -.6   -.0   .$   .7


     .0   -.2    -.4   -.3   -.1    .1   .2          .Â«    .3    .2   -.0   -.3   -.Â»   -.*   -.0   -.4   -.7   -.4    .2   .7   .9


     .0   -.3    -.5   -.6   -.*   -.3   -.2         .8    .7    .S    .1   -.2   -.4   -.4   -.0   -.$   -.6   -.2    .4   .9 1.0


    â€”â€¢0   â€” .4   -.6   *Â»7   ~Â«6   â€”.6              1.0    .9    .6    .2   -.1   -.3         -.0   -.4   -.5   -.2    .4   .8




                                               FIGURE C-3.            CONTINUED
    MODE 9. SYMMETRIC                            MODE 10. ANTISYMMETRIC                          MODE 11. SYMMETRIC
    FREQ. = 300.2                                FREQ. = 324.6                                   FREQ. = 343.7




    i.o    .8    .*                              -.0   -.6   -â€¢â€¢Â»                                -.2   -.3   -.6

     â€¢8    .6    .2   â€¢â€¢â€¢ 3   ~.6                                                                 .0   -.1   -.4   -.7   -.8
                                                  .0   -.6   -.8    -â€¢Â«    *2

     .3    .2   -.1   -.4     -.7   -.6                                          I>0              .0    .1   -.1   -.5   -.6   -.4
                                                  .0   -.5   -â€¢*    -â€¢!â€¢   â€¢*

    -.1   -.2   -.Â«   -.5     -.S -.3
                                                  .0   -.*   -Â«Â»      â€¢!    -7   l
                                                                                     Â«Â°          1.0    .8    .3   -.1   -.2    .1
o
i   -.3   -.3   -.3   -.3     -.2    .1    .Â»    -.0   -.3   -.3      .0    .5       .8    .7     .V    .7    .3    .1    .1    .*   .6

    -.2   -.2   -.2   -.0      .2    .â€¢>    .7    .0   -.3   -Â«*    -Â«2     -1       '3    .3     .3    .2   -.0   -.1    .1    .4   .6

     .0    .0    .1    .2      .4    .6     .7    .0   -.2   -â€¢*    -â€¢Â»    -Â«3 -Â«2        -.3    -.Â»   -.*   -.Â»   -.5   -.2    .2   .Â»

     .2    .2    .1    .1      .2    .4     .i    .0   -.1   -.2    -.3    -.*   -Â«5      -.fc   -.4   -.6   -.7   -.6   -.3    .0   .2

     .3    .2    .1 -.1       -.1   -.1     .1   -.0    .Â»    .2      .1   -.2   -.*      -.*    -.1   -.2   -.3   -.4   -.2   -.0   .1

     .3    .2 -.1     -.3     -.4   -.5    -.Â»                                                    .A    .i    .3    .0    .0    .1   .1
                                                 -.0    .1     â€¢*     â€¢*    Â«Z "*Â°        'â€¢*

     .3    .2 -.1     -.*     -.7   -.7
                                                 -.0    .*     -7     â€¢6    â€¢*       *2          1.0    .Â»    .*   .2     .1    .1




                                                 FIGURE C-3.               CONTINUED
     MODE 12. ANTISYMMETRIC                      MODE 13. SYMMETRIC                       MODE H. SYMMETRIC
     FREQ. = 356.9                               FREQ. = 366.1                            FREQ. = 381.0




                                                                                           1.0    .7    .0
     -.0   -.7   -1.0                           -.7   -.*   -.1

                                                                                            .7    .0   -.2   -.6   -.4
     -.0   -.6   -.9    -.6   -.3               -.5   -.3    .2    .f    .7

                                                                                            .2   -.1   -.5   -.6   -.1   .4
      .0   -.3   -.3    -.1    .1    .3         -.2   -.0    .3    .5    .5    .3

                                                                                           -.1   -.2   -.*   -.4    .2   .7
      .0    .1    .3     .4    .4    .3          .1    .1    .1    .2    .1   -.1
o                                                                                           .1   -.1   -.3   -.2    .3    .Â« 1.0
I    -.0    .4    .6     .6    .4    .0   -.3    .2    .1   -.1   -.3   -.3   -.3   -.3
M
ro                                                                                          .Â»    .3   -.1   -.2    .1    .9   .Â»
     -.0    .4    .6     .*    .1   -.4   -.7    .3    .1   -.3   -.5   -.Â»   -.2   -.0

                                                                                            .7    .4   -.0   -.4   -.4   -.2   -.2
     -.0    .2    .2     .1   -.2   -.6   -.6    .4    .2   -.3   -.5   -.2    .2    .*

                                                                                            .J    .3   -.1   -.4   -.Â»   -.5   -.Â»
     -.0   -.1   -.1    -.2   -.2   -.4   -.i    .5    .)   -.2   -.4   -.0    .6   .">

                                                                                            .2    .1   -.1   -.2   -.2   -.2   -.3
     -.0   -.4   -.Â»    -.2    .1    .2    .1    .6    .3   -.2   -.4   -.0    .7 1.0

                                                                                           -.2   -.2   -.1    .1    .4    .*    .3
     -.0   -.Â»   -.6    -.1    .5    .8   .8     .Â»    .2   -.3   -.6   -.3    .3    .6

                                                                                           -.4   -.3   -.1    .3    .7    .8
      .0   -.Â»   -.6    -.1    .6 1.0            .Â»    .2   -.4   -.7   -.Â»   -.1




                                                 FIGURE C-3. CONTINUED
     MODE 15. ANTISYMMETRIC                        MODE 16. SYMMETRIC                      MODE 17. ANTISYMMETRIC
     FREQ. = 393.3                                 FREQ. = 418.4                           FREQ. = 124.0




       .0   -.Â»   -.6                                                                       .0   -.7   -.9
                                                  .4    .Â»    .4

       .0   -.4   -.4    .3   .9                                                            .0   -.i   -.6   -.2    .1
                                                  â€¢1    .2    .2   -.1   -.3

       .0   -.4   -.2    .4   1.0    .9                                                     .0   -.0    .1    .2    .2    .1
                                                 -.4   -.4   -.1   -.1   -.4 -.4

       .0   -.4   -.1    .2    .4    .2                                                     .0    .4    .6    .5    .2   -.1
                                                 -.7   -.4    .0    .2   -.0   -.2
o
i    -.0    -.3   -.4   -.2   -.1 -.4     -.7    -.4   -.1    .4    .6    .3 -.2     -.4
                                                                                           -.0    .4    .5    .2   -.2   -.4   -.4
M
UJ
     -.0    -.2   -.2   -.2   -.2   -.Â»   -.6                                              -.0    .2    .1 -.3     -.4   -.3   -.1
                                                 -.1    .1    .6    .7    .3 -.2     -.4

      -.0    .0    .1    .2    .1 -.1     -.2                                              -.0 -.0     -.3 -.4 -.4        .2    .i
                                                â€¢-.1   -.0    .2    .3    .1 -.3     -.4

     -.0     .2    .1    .4    .4    .3    .1    -.2   -.2   -.3   -.3   -.2 -.1     -.1   -.0    .0   -.2   -.4   -.1    .6 1.0

     -.0     .1    .2    .2    .3    .3    .3     .1 -.1     -.4   -.5 .-.1    .3    .4    -.0    .3    .1   -.2   -.1    .4   .Â«


                                                  .7    .3   -.3   -.5    .0   .6     .7   -.0    .6    .5 -.1     -.4   -.2   .2


                                                 1.0    .6   -.2   -.4    .1   .6          -.0   .7     .6 -.1     -.7   -.7




                                                FIGURE C-3.              CONTINUED
     MODE 18. SYMMETRIC                                            MODE 19. ANTISYMMETRIC
     FREQ. = 134.1                                                 FREQ. = U47.9




        -.Â» -.1     .Â«                                                  -.0   .5    .4


        -.6   -.1    .8   1.0    .6                                     -.0   .4    .3    -.1   -.1


        -.8   -.4    .3    .i   -.0   -.Â»                               -.0   .1 -.1      -.3   -.1   .3


        -.6   -.4   -.1   -.2   -.Â»   -.7                                .0   .0   -.3    -.*   -.1    .*


o        .2    .1   -.0   -.3   -.4   -.2   .1                           .0   .2   -.1    -.5   -.1    .7 1.0
i.
         .7    .6    .2   -.1   -.0    .4   .7                           .0   .6    .3    -.4   -.4    .3   .6


         .4    .3    .1   -.1    .1    .5   .7                           .0   .9    .6    -.4   -.7   -.2   .1

        -.3   -.3   -.3   -.3   -.2   -.0   .2                           .0   .9    .ft   -.3   -.7   -.2   .1


        -.6   -.4   -.2   -.1   -.3   -.5   -.*                          .0   .6    .3    -.4   -.3    .3   .6


        -.3   -.0    .4    .4    .0   -.4   -.3                          .0   .2   -.1    -.5   -.1    .7   .9

        -.0    .3    .7    .8    .3   -.0                                .0   .1   -.3    -.6   -.1   .Â»




                                              FIGURE C-3.   CONCLUDED
TABLE C-l. EXAMPLE PROGRAM OUTPUT
       Phase III Test Article
Angle subtended by floor edge with
vertical, 8^ = 56.6 degrees




MODE     FREQUENCY                      GEN.MASS

   0           0.0           SYrtn      2.59631
   I         99.501          ANTI       1.03531
   2      120.374            SYrt.1      .72535
   3      175.689            A<<TI       .68099
   *      137.927            SYM1        .72*00
   5      220.381            SYflrt      â€¢*9S15
   6      253.162            ANTI        .5*535
   7      259.176            srÂ»,i       .50751
   8      2*9.67*            ANTI        .51521
   9      30U.18*            SYMrt       .36571
  10      32*. 597           ANTI        .*2606
  11      3*3.723            SYrt.1      â€¢*5**0
  12      356.9*9            ANTI        â€¢*6005
  13      366.051            SYMrt       .36319
  1*      381.030            SYnn        .398*1
  15      393.310            ANTI        .2899*
  16      *13.37*            SYrtil      .3*805
  17      *2*.029            ANTI        .37055
  18      *3*.105            SYMM        .*02**
  19      'i <t 7 . 3 '6 1   A -N T I    .*5*90




                       C-15
        APPENDIX D

 FUSELAGE STRUCTURAL MODEL:
CYLINDER WITH INTEGRAL FLOOR
             APPENDIX D - FUSELAGE STRUCTURAL MODEL



The fuselage modal characteristics are defined by the eigen-
         i> _
vectors 4* (x), resonance frequencies u , and the mode normaliza-
tion given by the constant Mr (the modal mass). In the present
model, these quantities are computed for a ring-stringer
stiffened cylinder with a floor partition that is structurally
an integral part of the fuselage.


The basis of the structural model is an analysis of the free
vibrations of a circular cylindrical shell with a longitudinal
interior plate (Fig.D-1) by Peterson and Boyd [13>14]. A review
of their analytical approach is presented in this appendix and
then the generalization of their results to enable calculations
for the ring-stringer stiffened shell is considered.

Displacement   Functions


The displacement functions are assumed to be finite series.   For
the shell:
                           M*   n*



                           M*   n*



                           M*   n*

                     =
                         M?0 n?C


The plate functions upj Vp, wp are similarly expanded.


The longitudinal functions X(x) are the same for the plate and
the shell. These functions are expressed in terras of a single
function <{>..( x), in the following manner:



                                     D-l
FIGURE D-1.   CIRCULAR CYLINDRICAL SHELL WITH A
              LONGITUDINAL PARTITION




                        D-2
                       X
                           uM = *M (x >
                       X
                           vM = Vx)                                 (D.2)
                       X
                           wM = Vx)        '

The functions ^(x)         are the mode shapes of a uniform beam.

The boundary conditions used in this model are those of a
supported beam, so ^M(x) = sinMirx/L. Note here that the shell
axial coordinate is x. In the cylindrical coordinate system
used in the body of this report, the axial coordinate is z. No
confusion should result from this temporary change in nomencla-
ture.

The circumferential functions for the symmetric modes of the
shell are
                 fy = cos n6
                  un
                 V. = sln n9
                 *wn = cos          n0


  For the antisymmetric modes,                  .                   (D.3)
                 \1> = sin n8 .
                  un
                 ^vn = -cos n9

                 ^wn = Sln n9
A similar set is used for the symmetric and antisymmetric modes
of the plate (floor).

Constraint Equations

The floor partition can be taken to be fixed or pinned, (hinged)
along the line of attachment to the shell. -For a rigid
attachment, the shell and plate displacements obey the following
relations



                                          D-3
                         u       = u
                             s         p
                         w   sin6, + v cos9, = v
                             s     1    s      -1   p
                         w c o s 6 n - v sin0, = w
                           s       1    si          p
                         v
                           s   I          3w
                                            --    0
                          r    r 96        8y

In the case of a hinged connection the last equation is dropped.
Equations of Motion

Peterson [13] used Hamilton's principle to derive the equations
of motion. He assumed that the cylinder was of uniform thick-
ness t and allowed for different modulii Ex and Eg, but no
stiffeners. Following [13], the displacement functions are
written in the matrix form
                     u
                     v           = . [N s ]
                                                                         (D.5).
                     w

w h e r e [ N 0 ] is a m a t r i x of size 3 x 3M*n* and {q} is a v e c t o r oi
          O                                          '

the generalized coordinates of the shell given by
                                       (â€” \
                                        u
                                         s
                                                                         (D.6)
                                           W


where

                                               ol        ol



                  on*                          on        on              (D.7)
                     *                         in*
The displacements of the plate are expressed in the matrix form


                                     =    [N ] {q } ,                 (D.8)
                                            P    P


where the elements of (q } are the generalized coordinates of
the plate, arranged in the same manner as the elements of {q s}.
For either the shell or plate the strain energy can be expressed
as

                           U =   i / (a)T (e}dS ,                     (D.9)
                                  JS

where (a) is a vector of stress resultants and fe) is a vector
of strains and curvatures for the plate or shell.

For a linearly elastic material,
                           (a) = [D] (e)     ,                        (D.10)

where [D] is a matrix of elastic constants. The strain-
displacement relations, obtained from Love's shell theory and
classical plate theory, have the form

                      (e) = [G] {u}, where (u) =   Jv \       .       (D.ll)



Substituting Eqs.(D.lO) and (D.ll) into (D.9), and using
Eq. (D.5) or (D.8) leads to
        U = \ Â£       ([G] [N] fq})T [D] [G] [N] fq) dS           .   (D.12)

For either the shell or the plate the kinetic energy is (in
terms of the generalized coordinates)

                          U = | {q}T[K]{q)                ,              (D.13)
where             "

                       [K] =   / [[G][N]]T [D][G][N] dS       .       (D.lH)


                                    D-5
Writing the strain energies for the shell and plate as

        U
       s = X}T[Ks]{^} and Up â€¢            !VT[K
gives the total strain energy:




The kinetic energy of the plate or shell is

            T = \
                d
                  / p{u}T{u) dS.
                      S
In terms of the generalized coordinates

                T = | /s p{q}T[N]T[N]{q) dS         .

The mass matrix is defined as

                M = / p[N]T [N] dS ,
                     S
giving for either shell or plate

                T =       {q}TOl]{q}


The total kinetic energy for the system is the sum of the
kinetic energies of the shell and plate, T = Ts + Tp, yielding




where



is the combined vector of all the generalized coordinates of the
shell and plate.

The components of the coordinate vector {q} are not independent
because the constraint equations must be introduced to insure
displacement compatibility at the interface between the plate

                                 D-6
and shell. The equations expressing this compatibility can be
written in terms of the generalized coordinates in the following
matrix form:
                          CG]{q} = (0)    .              (D.17)

Applying Hamilton's Principle and adjoining the constraint
equations by introducing a vector of Lagrange multipliers in the
standard way leads to the equations of motion and constraint for
the system.

If (q) is partitioned into a set of independent coordinates tq^
and dependent coordinates {q~}, the constraint equations can be
manipulated and the dependent coordinates and Lagrange multi-
pliers can be algebraically eliminated. The equations of motion
then take the form:
                       CM] {q^} + CK](qi) = (0}   ,      (D.18)

in which
              CM] = [E]T[M*][E], [K] = [E]T[K*][E] ,     (D.19)

where

               [E] =                                     (D.20)



and GI and C2 are obtained from the partitioned constraint
equations

                            = (0)                        (D.21)

The eigenvalue problem is obtained by letting (q-^ vary harmoni-
cally with time to yield finally


                                                         (D.22)




                                D-7
Now, the primary concern In this appendix is to modify the Peterson
results to enable calculations for a stiffened shell. Prom Eqs.
(D.10) and (D.ll),
                                     (a s } = [D](e s} = [D][G](uJ
Peterson's results for the above (Appendix A of Ref.[13]) can
be written in the modified form
                                                                                                r
                                                                                                     â€¢*
   'N X             kXS3               I v k â€”                          1
                                                                         vk
                        3~^"           r x 939                          r x 9                   u
                                                                                                     s
   N                vAk â€”              - k   â€”                          - k
       y             6 x3x             r  9R 36                         r 6R

   N                â€”G   nt^TTT        G    ^t   -r                     0
       xy           r x6 39                x9    3x
            ^   _
                                                                        2
                                                                                               * V        (D.23)
                                     13*                           da               i 3'2            s
   M                0          v D   -o â€” -                  D     -         M   D 1 8
       x                        x U 9 r 2 39                 D
                                                              xs3x2          V
                                                                               xÂ°9 r 2 3 9 2
                                                                   9
   M                0          D 1 3'             â€¢          -v
                                                              J LD   '         - l 2 DD 9
                                                                                          '
       y                       9 r2 39                         9 x 3x 2          r 9 R 39 2

   M                0      r     t3 1 3 *                               t3   2 32               w
       xy                   â€¢'x6 12 r .3x                     x9        12   r 3x39                 s


In Eq.(D.23), Peterson's kX , k_,
                               D
                                  D X , and Dt)
                                              Q have been replaced at
various points in the matrix by the augmented terms

                                k
                                    xs â€¢kx +l^              stringer

                                k
                                    6R = k                  ring                                    (D.21J)
                                D xs = Dx.
                                                       d / stringer

                                D
                                 9R = D9
                                                      W     ring
The result may be compared to Eqs. (25)-(27) on Page 10 of Mikulas
and McElman [15]- If the assumption is made that the stiffeners
used by Mikulas and McElman are symmetric about the skin (i.e.,
zs and zr are zero), the equations are very similar except that
the terms with the asterisks do not appear.

                                                      D-8
    The strain energy term is obtained from Eq.(D.12).                               The result
                     T
    of concern is [G] [D][G] and is given by


,. 922     iz n t 92 2       1
                               \)k d
                                    a2   1
                                       + r; t Â°
                                               22                    1
                                                                        Mv 9
"xs 9x     r   x9 99         r x 6 9x96 r xQ 9x98                    r2 Ve 96                 -

1     32     I     32                 2                2
 Â» i-      +   c t       1* lr Â°a + r t- "a     1                    1
                                                                       ir 8               X
                                                                                                M n 33 2
r 6 x 8x99    r xG^ 3x96 r2 k6R 962  x9^ 9x2                         rzK3R 99              r2    8 x9x 98


                         +D    ^^1_+        G      ^ 1 _32           _1             93        G t3 2 93
                              6 r1* 962          x6 12 r2 9x2J       r"          6R 963        xe 12 r2 9x296


^vk                                                              1                        aC 1 * J_ , , TV       la 2
r 9 x3-1
                         1
                                 -9        v D 1 2 33 2
                                                                 1
                                                                 --       1 ,-    -LTl                       -1- O
                              K1-                                    2 IC
      9x                 r    6R 98         x 6 r 969x           r          9R xs 9x" x 8 r 9x2982
                                                                                               +V D          2




                         _ 1 D 1L.              2      t3 92    +1 un 3" + 1 n 3"
                           r4 ^8 983            r2   x6 12 9x296 r2 8 x9x2962 r1*U6R 99"


                                                                 +     M             t3 3"
                                                                      r2          x0 12 9x2962

                                                                                                    (0.25;
    The equations of motion that result for the shell when the
    matrix (D.25) is used are almost identical to those of Mikulas
    [15], p. 8, or Leissa [16], p. 191. The differences are due to
    assumptions made in the analyses, but the. important main diagon-
    al terms are very similar in form.

    To incorporate the effects of the stiffeners in the Peterson
    analysis, the properties of the stiffeners are "smeared-out",
    i.e., averaged over the shell surface as done in Ref.[15]. An
    equivalent skin thickness, t, is defined by




    where t is the actual skin thickness. A and A^ are the
           s                                s      R
    stringer and ring frame cross-sectional areas, and d and Â£ are



                                          D-9
the stringer and ring spacings.         Using this thickness, the skin
stiffnesses are computed from

                      k    = k    = Et
                       X     ~B         I_v 2

and the skin rigidities with

                                     Et3
                      Dvx = D6fl =
                                     12(l-v2)

In (D.25), kxs and kQR revert back to kx and kg (as originally
used by Peterson) but are computed with the equivalent skin
thickness. D    and DQR revert back to DX and DQ everywhere
except in the third diagonal term and are also computed using
the equivalent thickness as above. In the third diagonal term D
and DQR are computed from the results in (D.24) where D and
Dg are computed for the actual skin thickness.

When these modifications are incorporated, it can be seen that
reasonable approximations are found for the first two diagonal
terms and for the off-diagonal terms but the skin stiffnesses
will be somewhat higher than they would have been had k X S and
kQR been used (i.e., the results in (D.24)).

The Mode Shapes (Eigenvectors)

The eigenvectors for the fuselage model are the displacement's u,
v, and w for each eigenvalue, wr . The w component is the
                     r â€”
desired mode shape ty (x) . This mode shape encompasses both the
plate and shell normal displacements. The maximum normal dis-
placement computed on either plate or shell is assigned the
value of 1.0, and all other values of u, v, and w at other
positions are divided by that maximum value for normalization
purposes.




                                 D-10
The mode shapes for the symmetric modes of the shell are
                                            n*
                                            â€”    ,â€ž,                   â€¢   (D-26)

and for antisymmetric modes
                                            n*
                   ^(z,6) =-sin ^           Z C^(-l)nsinn6 .               (D.27)
                                            n=l
In these two equations, z is again the axial coordinate and 8 is
                                                           G >*>

measured from the bottom of the cylinder. The Cj, are the
generalized coordinates for the shell (the same as the WMn  of
Eq.(D.7)) â€¢

The symmetric modes of the floor are
                                 n*
                      = sin         e            cos               ,       (D.28)
                                n=0

and the antisymmetric modes are
                                       n*
                   (z,x) = sin   L
                                                 sin L             .       (D.29)
               P                     n=0 Mn           p

Again, z is the axial coordinate measured from the forward end
of the cylinder and x is the distance measured horizontally in
the floor plane from the centerline of the fuselage to the
position of concern on the floor. Lp is the. width of the
floor and is given by

                          Lp = 2a sin 9O         >

                                                     pr
where 90 is the floor angle as shown in Pig. 1. The CMn are the
generalized coordinates for the floor plate. Note that ^ (x) is
the combined set for cylinder and floor, that is,


                                                       .                   (D.30)




                                     D-ll
Generalized Mass


The generalized mass must include all energy in both the
cylinder and floor and therefore is defined by

                       r2n              2        2          2
                                    ? , r            ,   r
                                      + v            + wr ) m ad6
                                    5        S          s       s
                       9=0
                                                                    (D.3D


                   tf
                   L   L
                           P    r2
                               (u
                                p + v
                                     p
                                      r2
                                        + w
                                             r2
                                           p } mpdx

where ms and m are the masses per unit of area of shell and
plate respectively, a is the cyli-nder radius, and L is the
cylinder length. Note that there are two components of the
modal mass, one for the shell and one for the plate. If a
particular mode r is, say, predominately a floor mode, M will
be dominated by the second term and the shell contribution will
then be small. For such a mode, the floor can be seen to re-
strain the motion induced by fuselage sidewall excitation.

Sample Output


Modes are ranked according to the occurrence of their resonance
frequencies and the values of the generalized coordinates
 si-*     or*
CMn and CMn for each mode are output. For each value of r,
there is a single value of M that defines the axial mode shape,
and a sequence of n's that defines the circumferential mode
shape. Table D-l gives the results for the first 32 modes of the
1.83m (72 in.) long cylinder used in the present validation study.
The values of n given in the table are those that contribute most
to the determination of the mode shape. Ohly 5 terms are retained
for the shell and 3 for the floor. Fig.D-2 shows an example of a
typical mode shape, in particular, for the first mode -of Table D-l
It is 'apparent from the figure and also from the computed gener-
ized mass, that the mode shown is basically a floor mode.



                                            D-12
                       TABLE D-l. EXAMPLE PROGRAM OUTPUT
           Phase III Test Article: 1.803m (71 in.) long cylinder,
stiffened 0.0008m (0.032in) skin, 0.508m (20 in.) radius with floor at 56.6Â°


     NODE FREQ      nOOE       SHELL           PLATE         GENERALIZED MASS (KG)
      NO (HZ)       TYPE   H    N CHN      H    N CNN       TOTAL    SHELL W PLATE U
       1   188.52   SYHM   1   2 -.06610   1   0   .41496   1.13889    .02830   1.10253
                           1   3 -.03362   1   2   .33940
                           1   4 .02042    1   1   .23432
                           1   1 .01776
                           1   5 -.00589
       I   208.21   SYNM   1   2 -.07691   1   1 1.42371    1.12644    .05670   1.05950
                           1   4 .06646    1   2 -.34033
                           1   5 -.03793   1   0 -.30912
                           1   3 -.02065
                           1   1 -.01360
       3   217.88   SYMH   2   <i .01270   2   0   .44544   1.06241    .00143   1.06071
                           2   2 -.01001   2   2   .41198
                           2   5 -.00550   2   1   .14239
                           2   1 .00391
                           2   3 -.00293
           231.01   SYHN   2   4 .04328    2   1 1.08434    1.05432    .01444   1.03897
                           2   5 -.03088   2   3 .20954
                           2   2 -.01367   2   2 -.13739
                           2   8 -.00803
                           2   7 .00740
       5   293.25   SVHH   3   4 .00824    3   0   .46520   1.05532    .00050   1.05476
                           3   5 -.00455   3   2   .43756
                           3   2 -.00386   3   1   .10293
                           3   1 .00195
                           3   7 .00119
       6   301.93   SYHH   1   2 .60434    1   2   .34208   3.35573   2.32876    .47468
                           1   3 .39210    1   1   .24271
                           1   5 -.02343   1   3   .11650
                           1   4 .01026
                           1   b .00956
       7   303.67   SYNM   3   4 .03058    3   1 1.00245    1.04019    .00869   1.03105
                           3   5 -.02783   3   3 .19801
                           3   8 -.00764   3   2 -.08872
                           3   2 -.00758
                           3   7 .00698
       6   318.73   ANTI   1   2 -.69794   1   1 -.71809    5.33569   2.87324   1.56559
                           1   3 .33122    1   2 -.37744
                           1   1 -.17597   1   3 -.13196
                           1   4 -.10995
                           1   5 .03684




                                           D-13
STIFFENED .032 IN CYLINDER, 20 IN RADIUS,. W I T H FLOOR AT 56.6 DECREES


MODE FREO     100E       SHELL           PLATE         GENERALIZED MASS (KG)
 NO (H/)      TYPE   n    N CHN      H    N CMN       TOTAL    SHELL H PLATE tf

 t   346.71   ANTI   1   3  .65759   1   2 -.37430    3.07613   2.38329    .30019
                     1   2  .29630   1   1 -.10529
                     1   1  .08228   1   3 -.02409
                     1   4 .06592
                     1   5 -.02470

10   434.31   SYMM   4   4 .00568    4   0   .47682   1.05268    .00025   1.05241
                     4   5 -.00383   4   2   .45133
                     4   2 -.00218   4   1   .08093
                     4   1 .00130
                     4   7 .00106

11   441.78   SYHH   4   5 -.02558   4   1  .96440    1.03311    .00632   1.02654
                     4   4 .02362    4   3  .19308
                     4   8 -.00753   4   2 -.06599
                     4   7 .00695
                     4   2 -.00602

12   470.53   ANTI   2   3 .42411    2   2 -.48203    2.27504    .82788   1.34321
                     2   2 -.05284   2   1 -.46964
                     2   4 -.03870   2   3 -.24148
                     2   5 -.01810
                     2   6 .01552

13   502.23   SYHH   1   1 -.76763   1   2 .66675     6.31376   2.76903    .76399
                     1   4 -.12362   1   0 -.17384
                     1   3 -.11395   1   4 .05223
                     1   6 .01293
                     1   0 .01078

14   528.78   ANTI   1   4 -.66794   1   1 1.12932    3.71841   2.70485    .23627
                     1   1 .31690    1   2- 1.02632
                     1   2 -.22781   1   3 .92727
                     1   5 .05974
                     1   7 -.02769

15   555.05   SYHH   1   4 .61552    1   3 -.26052    3.02626   2.55327    .18097
                     1   3 .37347    1   2 -.09653
                     1   2 -.18507   1   1 -.08745
                     1   1 -.09309
                     1   5 .07360

lb   556.43   ANTI   2   3 .30944    2   1 1.00231    1.65729    .48102   1.10579
                     2   2 .10406    2   3 .96170
                     2   1 .02332    2   2 -.46528
                     2   6 .01193
                     2   7 -.00791
STIFFENED .032 IN CYLINDER, 20 IN RADIUS, M l T H FLOOR AT 56.6 DEGREES


MJOE FREO     MODE       SHELL             PLATE           GENERALISED MASS (KG)
 NO (H/l      TYPE   N    N   CNN      N    N   CNN       TOTAL    SHELL W PLATE M
1?   560.65   ANTI   1   1 -.25827     1    3   .55091    2.00966    .54454   1.11528
                     1   4 .19682      1    1   .53220
                     1   3 .11259      1    2   .14949
                     1   2 -.05185
                     1   5 .02207

18   572.86   ANTI   3   3 -.03551     3    1   .55890    1.22949    .04255   1.18227
                     3   4 .03125      3    3   .46354
                     3   2 .02289      3    2   .21649
                     3   5 .01994
                     3   6 -.01569

     591.88   SYHM   2   3 .42559      2    2 .06831      1.73996   1.52659    .00197
                     2   2 .28611      2    3 -.05649
                     2   4 .27539      2    0 -.02208
                     2   5 .03191
                     2   6 -.02568

20   607.50   ANTI   2   4 .44272      2    2 .84374      2.88669   1.78872    .88336
                     2   3 .32362      2    4 .25752
                     2   2 .29967      2    3 -.05258
                     2   5 .06404
                     2   6 -.05875

21   626.01   ANTI   3   3 -.29317     3    2 1.58856     1.95333    .66669   1.23632
                     3   4 .20194      3    3 -.54749
                     3   6 -.09539     3    4 .44915
                     3   5 .08096
                     3   2 .04894

22   632.02   ANTI   1   1 .22426      1    2   .64039    1.99704    .51331   1.07277
                     1   2 -.13579     1    4   .23344
                     1   3 .12769      1    3   .20029
                     1   5 .12610
                     1   4 .09665

23   636.15   SYHH   5   4 .00462      5    0   .48042    1.05173    .00018   1.05154
                     5   5 -.00363     5    2   .45601
                     5   2 -.00161     5    1   .0737tt
                     5   1 .00102
                     5   7 .00100

     641.20   SYNH   5   5 -.02553     5    1 .95366      1.03218    .00591   1.02608
                     5   4 .02158      5    3 .19080
                     5   8 -.00763     5    2 -.05895
                     5   7    .00715
                     5   2 -.00591




                                           D-15
STIFFENED .032 IN C Y L I N D E R , 20 IN RADIUS, WITH FLOOR AT 56.6 DEGREES

NOOt FREO     NOUE      SHELL               PLATE           GENERALIZED MASS (KG)
 NO (HZI      TTPE    fl N CHN         Â«     N CNN         TOTAL     SHELL M   PLATE w
25   648.70   srrin   2   4   .54137   2    3 -.31842      3.12167   2.22892    .58061
                      2   2 -.45147    2    2 -.31722
                      2   5 .01850     2    0 .11216
                      2   1 .01384
                      2   6 -.00425
26   663.30   ANTI    4   3 -.03615    4 1        .60174   1.17010    .00997   1.15917
                      4   4 .01914     4 3        .53040
                      4   5 .01472     4 2        .13228
                      4   6 -.01272
                      4   2 .01226
27   716.23   ANTI    4   4.11594      4    2 1.12205      1.33482    .16827   1.15854
                      4 3 -.11451      4    4 .34731
                      4 6 -.07550      4    3 -.19925
                      4 5 .05392
                      4 7 .03384

28   717.33   ANTI    2   2 -.42010    2    2     .55423   2.32071   1.11855    .98835
                      2   3 .16269     2    4     .29992
                      2   4 -.15887    2    3     .25016
                      2   5 .11998
                      2   6 -.07240
29   738.44   ANTI    1   4 -.59228    1    2 .81512       3.63204   1.85287    .93833
                      1   3 .14987     1    4 .50058
                      1   1 -.12843    1    3 -.13113
                      1   6 -.09905
                      1   5 -.07457
30   761.91   SYNH    3   4 -.63950    3    3 .31731       2.90922   2.41279    .31644
                      3   3 -.35980    3    2 .15446
                      3   5 -.00670    3    0 -.05975
                      3   2 .00615
                      3   1 -.00485
31   779.76   ANTI    3   3 -.60810    3    2 -.25398      2.59160   2.12986    .26505
                      3   4 -.29025    3    4 -.16348
                      3   5 -.10698    3    3 -.16054
                      3   2 -.08652
                      3   6 .04237
32   811.04   ANTI    2   4  .44856    2    2 -.33993      2.10595   1.69469    .20392
                      2   5 .28040     2    4 -.28072
                      2   2 -.25218    2    3 .05882
                      2   1 -.14779
                      2   3 -.09074




                                           D-16
       MODE NUMBER 1
       FREQUENCY = 188.51
       SYMMETRIC MODE
       M =1


                                                 TOP C/L
                                                  *.
                                                  *.
                                                  *.
                                                  *.
                                                  *.
                                                  *.
                                                   *
                                                   *    SHELL
                                                   *
                                                   .*   DISPLACEMENT
                                                       (Cylinder Wall)
                                                   .*
                                                   .*
                                                    .*
                                                   .*
                                                   . *
              Composite                            . *
                                                   . *
                                                   .*
                                                   . *
                                                   . *
                                                   .*
                    **-1.0                         .*
                                                   .*


                                                 *F = FLOOR LOCATION
       FLOOR
       DISPLACEMENT                              *.
                       â€” 0.5                     *.
                                                 *.
                                                 *.
                                                 *.
                                                 *.
                                                 *.
              C/L                     'SIDE      *.
                                                 *.
                                                 *.
                                                  *
                                              BOTTOM C/L




FIGURE D-2.   EXAMPLE SHELL MODE ( Z DEPENDENCY SUPPRESSED)




                               D-17
F1g.D-3 shows a n o t h e r mode, t h e sixth mode o f Table D-1.   Itis
found t o b e basically a s h e l l mode.
     MODE NUMBER 6
     FREQUENCY = 301.93
     SYMMETRIC MODE
     M = 1

                                               Top C/L
          x            v


                                                             0.5       *
                                      -0.5
                                                                   *       1.0
                                                 â€¢
                                                 . *




                                                        SHELL
        COMPOSITE                                       DISPLACEMENT
                                                       (Cylinder Wall)




           .1.0


                                                 F =* FLOOR LOCATION
                                                       *
                                                 .      *
               *       0.5                       .      *
                                                 .      *
FLOOR                                            .      *
                   *
DISPLACEMENT                                     â€¢      *
                                                 .      *
                                                 .      *
  C/L                           â€¢ SIDE           .      *
                                                 .      *
                                                       *
                                             Bottom C/L
                              * *




        FIGURE D-3.          A SECOND EXAMPLE MODE




                                    D-19
       APPENDIX E

MODEL VALIDATION.STUDIES
                APPENDIX E - VALIDATION STUDIES



The models of Section 3 are based on fairly precise solutions of
the sound transmission problems. Nevertheless, the models will
have limited prediction accuracy due to errors inherent in the
input data that is used to describe the various physical systems
involved, i.e., exterior field, fuselage structure, cabin acous-
tic space, sidewall trim, etc. The primary goal of the present
modeling effort has been to minimize these errors through
elaborate, though limited, system models. Although the overall
quality that has been achieved is not predictable, it is
measurable, and a test has been devised for that purpose.

Test Hardware

The test configuration is very similar to that represented in
Figure 1. The actual test rig and hardware are shown in Figures
E-l through E-3. As seen in Figure E-l, the fuselage and the
propeller are located downstream of a nozzle that supplies air
to simulate airplane forward velocity. The fuselage model
itself is a cylinder 1.83m (72 in.) long and 1.02m (40 in.) in
diameter. The skin is 0.00081m (0.032 in.) thick and is
stiffened by eighteen (18) stringers spaced on 20Â° centers. The
stringers are 90Â° angles having dimensions of approximately
0.00953 x 0.0112 x 0.00051m (3/8 x 7/1.6 x 0.020 in.). They are
riveted to the inside of the skin and pass through cut-outs in
eight (8) internal ring frames that are spaced along the
cylinder every 0.2m (8 in.) The frames are aluminum channels
with dimensions of approximately 0.017 x 0.038 x 0.00081m (5/8 x
1-1/2 x 0.032 in.).

The cylinder has a structurally integral floor consisting of a
0.00081m (0.032 in.) plate stiffened by floor supports of the
same thickness spaced every 0.2m (8 in.). The supports extend



                               E-l
FIGURE E-1.    MODEL TEST FACILITY
              (Dimensions in meters)




                E-2
                                 0.00081 m ( 0 . 0 3 2 in.) skin
                                 1.016 m (40 in.) diameter
                                 x 1.83 m (72 in.) long
 0.046 m
(1.8 in.)

                                           0.00051 m ( 0 . 0 2 in.)
                                           stringer, 0.0095 x
                                           0.011 m (0.375 x 0.44 in.)

                       Trim Lining &
                       Insulation




                                                       0.039




                                           0.00081 m (0.032 in.)
                                           frame, 0.017 x 0.038 n
                                           (0.67 x 1.5 in.) channel,
                                           0.2 m (8 in.) spacing.
                                           8 req'd.



        0.00081 m ( 0 . 0 3 2 in.) floor beam,
        0.017 x 0.0.038 m (0.67 x 1.5) channel
        1.79 m (70.75 in.) long



        0.00081 m (0.032 in.) floor support at each frame


        0.00081 m (0.032 in.) floor, 1.83 m (72.0 in.) long,
        rivet to supports, bolt to skin, cutout to clear frames




      FIGURE E-2.     FUSELAGE MODEL




                       E-3
  Stiffener
      Clip for end ring and support attachment

                             floor



                     ^^j-         holes for screws
               _^^-^-^^^ /        to skin and end rings




                                  cutout to clear ring frames




                                      0.017


                   floor                       frame and floor beam
                   beam


cutout to clear floor beam   <-

 0.794
                                     0.003 R        â€¢floor

                                     0.01M         floor support




                                                    frame



                                                    skin




         FIGURE E-3. FLOOR ASSEMBLY
             (Dimensions in meters)
downward from the floor to the bottom of the cylinder. There
are also two floor beams (channels of the same dimensions as the
cylinder ring frames) that run longitudinally, each located
approximately 0.13m (5.1 in.) from the center of the floor. The
width of the floor is 0.85m (33.4 in.) leading to a floor angle
0 of 56.6 degrees (see Pig.D.I). The outer edge of the floor
is bolted to the cylinder wall. The cylinder is closed by
0.013m (1/2 in.) thick end caps that are used to support the
cylinder in the NASA Langley propeller test facility. The
entire fuselage assembly is constructed of 2024-T3 aluminum.

Propeller

The propeller is a three-bladed, 0.3 scale Hartzell for a Twin
Otter aircraft with a diameter of 0.76m (30 in.).  It is driven
by a 30 kw (40 horsepower) variable speed electric motor capable
.of turning it up to 8000 rpm. The propeller blades are
 Series 16 airfoils. The geometry of the blades is specified in
the input data to the ANOPP Propeller Noise Prediction program.

The data used to define the particular propeller used in the
present test are proprietary and thus are not included here. In
the present circumstance the angle-of-attack  and local chord
are specified as a function of radial location. Airfoil coordi-
nates are specified for several locations and then interpolated
as required with a cubic spline to fix these variables at all
locations on the blade.

Figure E-4 shows the grid coordinates used for the calculations
required in the-present test. There are 160 points on the upper
quarter of the cylinder. In the present test rig, each position
on the grid, i.e., (k,&) lying in the fuselage surface, has
coordinates defined by the equivalence relation
                     (k,Â£) ++   (X*, x*, x*)   ,

where (in meters):

                                E-5
      I-
      y
      Q
      HI
      UL
      a.
      UJ
      cc
      Ul
      UJ
      Q.
      o
      o:
      Q.
      o:
      o
      u.
      Q
      ui
      to
      g
      a:
      o
      a-
       i
      ui
      UJ
      o
      LL
S-6
            x* = 0.457 + 0.508. U-cos[(Â£-l) -ir/18]}

                     = -0.508 sin
and
                     = 0.622 - 0.089 (k-1) .

This grid covers all of the upper quarter surface of the
cylinder forward of the propeller and a somewhat greater amount
behind it. Because of the lengthy calculations involved in the
ANOPP program, the data for the lower quarter of the cylinder
seen by the propeller are obtained from the data for the top
quarter with the relation (imagining an identical grid below the
centerline)
                /                     **-   4- \   _       /                           4-      "N
            Â£-* \ -A- -i y â€¢*Â»â€¢ 03     o5    ^/     ~~   Â£~ \ â€¢"â€¢ "i ) ~~ â€¢" o J â€¢"â€¢ O5         10'      3



where Tk^   is a time delay given in milliseconds by the result

                                     _ 333.33             â€ž
                                             N

N is the propeller rpm and a                                     is in degrees and is given by
the result

                           a,                 -1,


The propeller harmonic amplitudes at corresponding points above
and below the centerline are given by

                                                         -ki
                                                    = A
                                                          H
                                     bottom                        top

and the corresponding phases (in degrees) are related by


                                                          H                    -~           x H x 360Â°
                                     bottom                      top




                                                           E-7
where T = BPF    is in milliseconds and H is the harmonic index,
This can also be written as
                       kfc        ,kÂ£          + 2BHa,
                   'H
                    bottom   H top
where B is the number of propeller blades.

Conversion to the coordinate system used in Figures 1 and 2 in
the body of this report is with the relations

                   z
                  k = ZP - X3          '
and (using 4> = ir/2 in Fig. 2)    g
                             I             \

          e
           , - \+ I""'1      (7-77] = *P + (*-X>         W   '
The coordinates of the grid point (k,Â£) are given by the
equivalence statement



In the present test, rp = 0.965m (38 in.) and zp = 0.662m
(2;?.5 in.). The resulting grid has spacing A of approximately
0.089m (3.5 in.). This spacing is sufficiently close to assure
a relatively smooth change in phase for each propeller harmonic
from grid point-to-point.

Test Description

The test program discussed in this appendix was conducted at
NASA Langley Research Center by NASA personnel. The main test
involved the transmission of propeller noise into the interior
of the model cylinder. For this test the cylinder and propeller
were mounted in an anechoic chamber in the configuration shown
in Figure E-l. Additional tests were performed in a reverbera-
tion chamber to measure the noise reduction associated with a
reverberant sound field. Also, decay measurements were made on
the acoustic field in the cylinder and the structural vibration
of the cylinder to determine empirical loss factors.


                                   E-8
The interior of the cylinder was treated with fiber glass blank-
ets with a density of 9.61 kg/m3 (0.6 Ib/ft3). The blankets
were applied in layers which were nominally 1.3 cm (0.5 inch)
thick, four layers with a total nominal thickness of 5.1 cm (2
inch) being applied to the curved surfaces and one layer to the
end plates. One face of each layer had a vinyl facing with a
thickness of 0.005 (0.002 inch); the total surface density of
one layer plus facing was 0.22 kg/m2 (0.045 Ib/ft2). On the
curved surface, three of the fiberglass layers were placed
between the frames and the fourth layer covered the frame caps.
The inner surface of the fiberglass treatment on the curved-
walls was covered with a trim septum consisting of a sheet of
epoxy/fiberglass NEMA G-10 (0.079 cm or 0.031 inch thick) from
floor to floor, and a sheet of vinyl (of the same thickness)
over the upper 120Â° of the cylinder. The installation is shown
diagrammatically in Figure E-5. The trim was hard-mounted to
the floor and attached to the frames by nine soft-mounted
screws. The total weight of the trim septum was 6.5& kg (14.51
Ib).

During the propeller noise test, sound levels inside the cylin-
der were measured using an array of eleven microphones which
could be located at any selected station along the cylinder and
could be rotated about the cylinder axis. Measurements were
made at a total of 196 locations, consisting of 49 locations at
each of four axial stations. The stations were chosen so that
the interior of the cylinder was divided into four segments of
equal volume. Figure E-6 shows the microphone locations on the
rotating array. The array was positioned at angular locations
  = 0Â°, _+ 51.5Â° and Â±103Â°. The radial positions of the micro-
phones were chosen such that all microphones were associated
with approximately equal cross-sectional areas. The sound
levels measured at the different microphone locations were
averaged on an energy basis to obtain space-average sound
pressure levels for each measurement axial station and for the
cylinder as a whole.

                             E-9
                                      '    \_Screws at
                                          3 Places on each
                                          Frame. Clearance
                                          Holes with Grommets



              0.08 cm Vinyl Bonded    '
              to Epoxy/Fiberglass


         0.08 cm Epoxy/Fiberglass
         Septum (NEMA C-10)




                                                      R = 0,46 m




                                                                   Angle Clip
      r-H(*~ 1.3 cm




FIGURE E-5.     CROSS-SECTION OF TEST CYLINDER SHOWING TRIM




                                     E-10
                         Mic    r/R
                         1,9    .250
                         2,10   .433
                         3,11   .559
                         U      .661
                         5      .750
                         6      .829
                         7      .901
                         8      .968




   3 Blade Prop
   7.6 cm Tip
   Clearance




Flow. Duct
(1.22 m Diam.)                           Test Cylinder
                                         (1.02 m Diam.)




   FIGURE E-6.    MICROPHONE LOCATIONS IN TEST CYLINDER




                                E-ll
Measurements were made by NASA at several test conditions, but
results for only one condition are considered in this appendix.
The airflow speed into the propeller was 23-b m/s (7B ft/sec)
and the propeller rotational speed was 4000 rpm. The resulting
fundamental, or first harmonic, of the blade passage frequency
is 200 Hz.

In the case of the noise reduction tests for reverberant excita-
tion, sound levels were measured at only two axial stations, one
at the mid-point of the cylinder and the other at the one-sixth
point. Symmetry was then assumed about the mid-point of the
cylinder length in order to calculate space-average sound
pressure levels.

The bulk of the data reduction was performed in terms of one-
third octave band spectra. However, a small amount of harrow-
band analysis was performed in order to obtain a better under-
standing of the data.

Measured Interior Sound Levels

Typical narrowband sound pressure level spectra measured at two
locations in the cylinder are shown in Figure E-7- The two
selected locations are close to the plane of rotation of the
propeller (X3/D = 0.015 where D is the propeller diameter),
microphone #1 being near to the center of the cylinder and #8
near to the periphery (as shown in Figure E-6). Figure E-7
shows that the contributions associated with the three lowest-
order harmonics are easily identified but that contributions
from higher-order harmonics may be difficult to identify. This
masking of the discrete frequency components by the broadband
signal limits the upper frequency bound on the useful propeller
noise data, particularly when, as in the present case, much of
the data presentation is in terms of one-third octave band
spectra.



                             E-12
               Station 1.1 cm aft of Propeller Plane,       >= 103Â°
               (a) Microphone 1,    r = 11.6 cm
      100




      80




      60

 ro
 Q.
 3
       10


 m
      20                                  I                                   I
 01         200      100      600        800       1000     1200      1100   1600   1800   2000
 01                                            Frequency, Hz

      120      (b) Microphone 8, r = 11. 7 cm


 n
      10
 Â§     Â°


      80




      60




      20                                            I
            200      400      600       800        1000     1200      1100   1600   1800   2000
                                               Frequency,    Hz




FIGURE E-7.       TYPICAL NARROWBAND SPECTRA OF INTERIOR SOUND
           ,      PRESSURE LEVELS




                                        E-13
Average one-third octave band sound pressure level spectra are
shown in Figure E-8 for each of the four axial stations of the
microphone array. Little variation in sound pressure level is
observed from station to station. The space-average spectrum
for the cylinder as a whole is plotted in Figure E-9, which
also contains the range of measured sound pressure levels. The
space-average values are compared in Figure E-10 with associated
95% confidence limits. Because of the large number of samples,
the 95^ confidence intervals are small.

The spectra show distinct peaks in the frequency bands centered
at 200, 400 and 630 Hz, the sound levels in these bands being
controlled by the contributions from the first, second and third
harmonics of the blade passage frequency. At higher frequen-
cies, the broadband contributions become important, as indicated
in Figure E-7, and the one-third octave band spectra are rela-
tively smooth. The harmonic components may be significantly
lower in level than are the corresponding one-third octave band
levels.

Propeller Noise Field

The analytical model to predict sound levels in the cylinder
uses, as data input, a description of the propeller noise field
(in terms of pressure amplitude and phase) computed for free-
field conditions using the NASA ANOPP computer program. The
blocked pressures are then calculated within the present analy-
tical model using the relationship given in Eq.(43).

During the test program at NASA, sound pressure levels were
measured at several free-field locations surrounding the model
propeller, and at other locations on a rigid-wall cylinder
placed close to the propeller. A brief comparison of the
measured and predicted sound levels has been performed to get an
indication of the accuracy with which the predictions fit the
100
                           X/R=-!.
                           X/R = 0.
                           X/R = 1.
                           X/R= 2.




30
          125    250      500     1000   2000   4000    8000
           ONE-THIRD GCTflVE BflND CENTER FREQUENCY, HZ



FIGURE E-8.    AVERAGE SOUND PRESSURE SPECTRA IN CYLINDER
              .AT DIFFERENT MEASUREMENT STATIONS
               (PROPELLER NOISE EXCITATION)



                           E-15
100




30
            125    250      500     1000   2000   4000    8000
             ONE-THIRD OCTflVE BflND CENTER FREQUENCY, HZ



     FIGURE E-9.   SPACE-AVERAGE AND RANGE OF VALUES FOR
                   PROPELLER-INDUCED SOUND LEVELS INSIDE
                   TEST CYLINDER



                           E-16
                               SPflCE-fl /ERRCE Â£
                               95% CON r IDENCE




 30
               125    250     500    3000      2000   1000     8000
                QNE-THIRD OCTflVE BflND CENTER FREQUENCY, HZ



FIGURE E-10.    SPACE-AVERAGE AND 95% CONFIDENCE LIMITS FOR
                PROPELLER-INDUCED SOUND LEVELS INSIDE
                TEST CYLINDER



                             E-17
test environment. This comparison was made for axial locations
associated with grid line Â£ = 1 shown in Figure E-4. The com-
parison was restricted to pressure level, because no phase data
were available from'the test program.

The comparison of measured and predicted free-field pressure
levels is shown in Figure E-ll. In this case both the measure-
ments and the predictions were performed by NASA personnel. The
agreement is generally good except at large distances from the
plane of rotation where the pressure levels are relatively low
and could be affected by broadband flow noise.

Figure E-12 contains the corresponding comparison for the
pressure field on a rigid cylinder (i.e., the blocked pressure).
The test data were obtained directly from NASA measurements and
the predictions from the application of Eq.(43) to the output of
ANOPP. The equation provides an empirical relationship for
calculating the effect of pressure reflections at the surface of
the cylinder. In general the predicted levels are higher than
the measured values, the differences being 0 to 5 dB at loca-
tions in the neighborhood of the plane of rotation where the
pressure levels are highest.

Acoustic Loss Factors

Acoustic reverberation decay measurements were made inside the
test cylinder using pink noise and sinusoidal excitations.
Acoustic absorption coefficients were computed from the
reverberation time TR using the relationship


                     =   17.6TTV

                     " coSTR

where S and V are,, respectively, the surface area and volume of




                                   E-18
                              i          i              i               r
                                                                Predicted
            First Harmonic
      130                                           o           Measured




      120



      110



S.    100
o
CM
            Second Harmonic
      120
OQ


â€¢Â»    110
tt>


0)

      100
0)

a.
T3    90
I
            Third Harmonic
      110



      100

                                                            o     o o
      90



                                                                        I
      (Forward) 1          0.5                    -0.5               -1 (Aft)
                      Distance from Propeller Plane, X _ / D



            FIGURE E-1U MEASURED AND PREDICTED FREE-FIELD
                          SOUND LEVELS FOR TEST PROPELLER



                                       E-19
                                                              Predicted
              First Harmonic                                  Measured
       130



       120



       110



       100

o
(N           Second Harmonic
 Â«     120
CO
T3

15     110



       100
 (A
 Â«
(X

C
       90
O
(ft
             Third Harmonic
       110



       100



       90



                                                                 1
       (Forward) 1           0.5         0          -0.5        -1   (Aft)
                        Distance from Propeller Plane, X./D



      FIGURE E-12.   MEASURED AND PREDICTED BLOCKED SOUND LEVELS
                     INDUCED BY PROPELLER ON TEST CYLINDER



                                        E-20
the interior of the cylinder. Values of a, averaged over
approximate one-third octave bands, are given in Figure E-13.

The acoustic loss factor nn was computed from the equation

                           c So.
                  n    =
                   n        Â¥^\T

Resulting values for the acoustic loss factor are plotted in
Figure E-l4.

Also contained in Figure E-14 are band-average values of the
acoustic loss factor calculated using the analytical model out-
lined in Appendix A. It is necessary in this analytical model
to assign a value to the structural loss factor rirp of the trim
septum. A' value of 0.5 was assumed in [7] for the trim loss
factor, on the basis of the best fit with test data then avail-
able. The same value was assumed initially for the present
analysis. At frequencies above 500 Hz, the measured data are
scattered about the predicted spectrum, but at lower frequencies
the predicted values are significantly higher than the measure-
ments .

When the trim structural loss factor was increased by a factor
of 2 to a value of 1.0, the calculated acoustic loss factor
decreased in the 250 Hz band (which contains a predicted reson-
ance frequency of the trim) but the change at other frequencies
was small or negligible. The disagreement between measurements
and predictions in the lower frequency -range was not affected to
any significant extent.

Structural Loss Factor

The damping of the cylinder structure was determined experi-
mentally from vibration decay measurements using sinusoidal



                                   E-21
1.4




  63       125     250    500          1000   2000   4000   8000
            ONE-THIRD OCTflVE BRND CENTER FREQUENCY, HZ



  FIGURE E-13.   MEASURED ACOUSTIC ABSORPTION COEFFICIENTS
                 IN TEST CYLINDER



                                E-22
        0.5


                                                               >
        0.2                                                  ii\\
                                                              i *
                                                             / Â»
                                                             'A *
                                                                                                                     ()
                                                         s A\
                                                  jf s




                                                             I Nâ€¢\
                                                 s^ s
                                            ^r   s
                                           r s




                                                                                                         /)
tn                                          .'


en
       0.05                                                                                     oÂ®         A^ QD
                                                         c
u                                                                                                                     I

fâ€”I                                                  0
                                            CD
fâ€”
in                                                                           o\             0        Â®
       0.02                                                                           \\             /
                                                                   13.
                                                                                                         G$D

                                                                                                                      \
                                                                                                     (
                                                                              I   b                            CCD
       0. 0]
                                                                         o                                                     CD
                                                                                           CD



      0.005
                   CD    MEflSUREE VflLUE s
                         CflLCULfll ED Vfll UES,         - RIM           LOSS FflCTC R = 0.
                                                                                                                       \       0
                                                                                                                      5
                         CflLCULfH ED VflL UES, 1 RIM LOSS FRC7Â£ R = 1. o                                                 \\

      0.002


      0.001
              10        20        50     100             200                 500                 1000          2000       5000      10000
                                                                    FREQUENCY, HZ


               FIGURE E-14.      MEASURED AND PREDICTED ACOUSTIC LOSS FACTORS
                                 FOR INTERIOR OF TEST CYLINDER (5.1 CM FIBERGLASS
                                 PLUS TRIM)




                                                 E-23
excitation. The resulting empirical values are plotted in
Figure E.I5, where they are compared with band-average values
predicted on the basis of the analytical model given in
Appendix A. The analytical model includes the influence of the
sidewall trim and requires, as an input, an assigned value for
the trim structural loss factor HT. The two calculated loss
factor spectra in Figure E-15 assumed trim loss factors of 0.5
and 1.0.

The comparison of measured and predicted values shows good
agreement at frequencies above 400 Hz, but the single experimen-
tal data point at lower frequencies is an order of magnitude
smaller than the corresponding predicted values. For diagnostic
purposes, an alternative analytical representation was construc-
ted whereby the structural loss factor was arbitrarily limited
to a maximum value of 0.15 in the frequency band below 400 Hz.

Predicted Interior Sound Levels

The model scale experiments discussed in the preceding sections
of this appendix were performed in order to obtain data for
comparison with sound levels predicted using the analytical
model described in this report. The predictions were made
using a computer program based on the analytical model outlined
in this report.

Initially, the interior sound levels were calculated without
placing any restraints on the structural loss factor for the
cylinder and with an assumed structural loss factor for the trim
of Hm = 0.5. Space-average sound pressure levels were computed
for the five lowest-order harmonics of the propeller blade
passage frequency. These levels are compared in Figures E-16
with the range of measured values and the associated space-
average levels, and in Figure E-17 with the average and 95%
confidence limits. The predicted sound levels refer to discrete



                             E-24
         ;u



         5




         2


                                                     ..--
             ]
                                                            \
                                                                \\
                                         â€¢" â€¢'          \

        0.5                                                 \ty
or                                                                   \i
ED                                                                    \\
tâ€”
ffi     0.2
u_                                ,
in
en                                                                         t tk
3 o.i
_i
d                                                                          K
a;                                               &
                                                                               \
=      0.05                                                                     \^=--

a;                                                                                                    A.   A
tn                                                                                         \
       0.02



       0.01
                                                                                                 'X
                   *   1WEASUREC) VALUIÂ£S
      0.005
                        (3ALCULA1FED VA LUES: 1HRIM LOSS> FACT<3R = 0. 5

                        :ALCULAIFED VA LUES: 1PRIM LOSS> FACT<3R = 1. 0
                       <:ALCULAIFED VA LUES W ITH UPPEIK LIMIT ON LO SS FACTC)R
      0.002



      n rim
              10       20       SO       100            200                 500         1000   2000        5000   10000
                                           FREQUENCY, HZ



                   FIGURE E-15.       MEASURED AND PREDICTED TOTAL STRUCTURAL
                                      LOSS FACTORS FOR TEST CYLINDER



                                                 E-25
      100


                                  CD     PfllN PR
a:
o_                     'i
                       'i                SPflCE-fl / E R f l C E     PL
                      ' i
a:                    ' i                MflX. FIN ] M I N .         EflSURED VflLUES
<->90

o
CM

UJ
a:



UJ
>
LU




to
CO
LU
ct;
Q-




10
a
â€¢z.
cc
on
Â£50
a:


a
a:

 i
LU




                                                    c
      30
           63   125         250         500       1000             2000    HOOO    8000
                 ONE-THIRD OCTflVE BRND CENTER FREQUENCY, HZ



FIGURE E-16.     COMPARISON OF PREDICTED AND MEASURED SOUND
                 UEVELS IN CYLINDER INDUCED BY PROPELLER
                 (MEAN AND RANGE OF VALUES)



                                       E-26
     100


                                CD     PfllN PR
                                       SPflCE-fl /E.RflCE i PL
e>
a;                                     95% CON r IDENCE L I M I T S




     30
                125       250         500     3000      2000      '4000   8000
                    ONE-THIRD OCTflVE BflND CENTER FREQUENCY, HZ



     FIGURE E-17.    COMPARISON OF PREDICTED AND MEASURED SOUND
                     1EVELS IN CYLINDER INDUCED BY PROPELLER
                     (MEAN AND 95% CONFIDENCE LIMITS)



                                     E-27
frequencies whereas the measured levels are associated with
one-third octave bands. However the harmonic frequencies of
200, 400, 600, 800 and 1000 Hz are centered within the corre-
sponding one-third octave bands so that there should be no
filter cut-off problems.

The comparisons show that the predicted levels are generally
lower than the corresponding measured one-third octave band
space-average levels. The largest difference occurs in the
highest order harmonic considered (1000 Hz) where the measured
levels may be dominated by broadband noise rather than the dis-
crete frequency component associated with the propeller blade
passage sound.

A small number of parametric studies have been performed in
order to assess the sensitivity of the analytical model to
various factors. These studies were limited to considerations
of the changes in trim and cylinder structural loss factors
discussed previously. In summary, the trim structural loss
factor was assigned a value of 1.0 and the cylinder structural
loss factor was limited to a maximum value of 0.15- The result-
ing predicted interior sound levels are shown in Figure E-18.
The effect of the changes of the loss factors was small except
for the first harmonic at 200 Hz. The predicted level at this
frequency now lies within 2 dB of the measured one-third octave
band space-average value, instead of being 10 dB lower as shown
in Figure E-17 for the initial calculations.

Further diagnostic analysis is highly desirable, particularly
with respect to the model for the sidewall treatment, but such
analysis was not possible in the present study.




                             E-28
      100


cr                               PfllN P          N
o_
                                SPflCE-fl         PL
IX                              95X CON I D E N C E LIMITS
<->90

o
CM

IU
QZ.

Â£80




to
to
UJ
a:
a.

      60




cr
tn
Â£50
cr                                   CD


a
a:

 i
LU

E5




      30
           63   125     250     500    1000   2000   4000    8000
                 QNE-THIPxD 0CTRVE BOND CENTER FREQUENCY, HZ



      FIGURE E-18. COMPARISON OF PREDICTED AND MEASURED SOUND
                   LEVELS IN CYLINDER INDUCED BY PROPELLER (TRIM
                   LOSS FACTOR = 1.0, TOTAL STRUCTURAL LOSS
                   FACTOR LIMITED TO 0.15 MAXIMUM)


                              E-29
Noise Reduction

In addition to predicting the transmission of propeller noise
into an airplane fuselage, the analytical model also contains a
capability for calculating the noise reduction associated with
a reverberant incident sound field. This capability has been
the subject of validation studies in earlier phases of the
development of the analytical model [3,7]. Additional compari-
sons are discussed here.

Interior sound pressure levels were measured at two axial
stations inside the cylinder, and average noise reductions
computed for the two stations. The resulting noise reduction
spectra are plotted in Figures E-19 and E-20- At frequencies of
160 Hz and above the two average spectra have similar values, as
was the case in Figure E-8 for propeller noise excitation.
There are, however, large differences in noise reductions for
the two stations at frequencies of 80 and 100 Hz.

Space-average noise reductions for the cylinder as a whole were
computed assuming that the sound field in the cylinder was
symmetrical about the mid-point of the cylinder length. The
space-average spectrum is shown in Figure E-21 with the range of
measured values and in Figure E-22 with 95% confidence limits.


Figures E-21 and E-22 also contain the space-average noise
reductions which were computed. It was assumed for these calcu-
lations that the trim structural loss factor was rim = 1-0 and
the structural loss factor n' was limited to a maximum value of
0.15.  In addition, allowance was made for noise transmission
through the end plates; the method used was the same as that in
[7] and it was applied to the four lowest frequency bands, 80 to
160 Hz. Without this modification the analytical model would
predict significantly higher noise reductions at low frequen-
cies.



                             E-30
     70


                    H/L=.50
                    95% CON

     60




     50


CD
Q




o


a
LU
a:
     30
LU




     20




     10




                      I   I   I   I          I   t   I   I   1   _   1   1

          63    125    250      500     1000   2000   4000    8000
                 ONE-THIRD QCTflVE BflND CENTER FREQUENCY, HZ



     FIGURE E-19.    AVERAGE NOISE REDUCTION MEASURED AT STATION
                     AT 50% OF CYLINDER LENGTH



                                      E-31
      70


                 H/L=.83
                 95% CON r !DENCE L I M I T S

      60




      50


en
a




a
Lul
a:
      30
to




      20




           63   125    250      500     1000   2000   4000    8000
                 ONE-THIRD OCTflVE BflND CENTER FREQUENCY, HZ



 FIGURE E-20.    AVERAGE NOISE REDUCTION MEASURED AT STATION
                 AT 83% OF CYLINDER LENGTH



                                  E-32
      70
                                                                                                                                                                       <k       A


                                            SPflCE-fl /ERflCE h O I S E RE 3 U C T I O N
                                            MflX. flN 3 MIN. h EflSURED VflLUES
                        A                   PfllN NO !SE REDL C T I O N
      60                                                                                                                                                       A




      50


CO
en
                    N


                            1

                                                                                                                                                                                        /       s
                                \


t-                                  \                                                                                                                                          â€¢'
                                    \
                                                                                                                                                                           /                     /
ZD
                                        \
                                                                                                                                                                       j                        /
LlJ                                     \
a:
                                                                                                                                                                   /           /â€”'/
      30
LJ
CO
                                                    \A                              '   k                      -'
                                                                                                                    ~            s
                                                                                                                                      â€¢^               J
                                                                                                                                                           J
                                                                                                                                                                           /            /
o                                                                                                   r- -, ~S

                                                                            A               S                                        t\                        j                /
                                        t   k                                   ., â€¢'           A


                                                                                                                                                                               1
      20                                1                                                                                       â€” -^ ^             /â€¢â€¢â€¢â€¢
                                                                                                                                                           t       \


                                                                                                                    .......
                                                                                                                                                                       \
                                1                                                                                                                                          '
                                                \               \^                              /               i
                             I          .           N                   N.                  /                  s                           \       /
                                                        \                   ^â€” ^
                _^--/               /
                                                            \                                                           A
                                                                \                           s

                            A                                       \               /
      10                /'                                              \       /


                                                                            V
                '




                !           1                               \               \                       1     1             1   1                  i               i                    1       1          1        t


           63                           125                                         250                        500              3000                               2000                         4000                8000
                                            3NE-7HIRD QCTflVE BflND CENTER FREQUENCY,                                                                                                                      HZ



      FIGURE E-21.                                   COMPARISON OF MEASURED AND PREDICTED SPACE-
                                                     AVERAGE NOISE REDUCTION FOR TEST CYLINDER
                                                    '(AVERAGE AND RANGE OF VALUES , TRIM LOSS
                                                     FACTOR = 1.0. TOTAL STRUCTURAL LOSS FACTOR
                                                     LIMITED TO 0.15 MAXIMUM)

                                                                                                               E-33
      70
                                                                                                i'   A

                                  c pnrc n                      OISE RE 3UCT10N
                                               :
                                  95% CON IDENCE L I M I T S
                    A.            PfllN NO ISE REDL CTION
      60                                                                               A




      50


CD
a



o
*â€”I
Â»-

a
UJ

                                                                                                 '' /
      30


                                       A
                                           i


                                                                           i                v
                                                                                                /'
                              i                    A                           '       '/



                             Ii
                                                       A
      20                        I
                              f
                A    ll                        / /.    "*   /

                                      vr://                       â€¢
                     A




                1        1                                        I   1            i    i            i   i          1   i
           63                125           250              500           1000              2000             HOOO           8000
                                  ONE-THIRD OCTflVE BflND CENTER FREQUENCY, HZ



      FIGURE E-22. COMPARISON OF MEASURED AND PREDICTED SPACE-
                  ^AVERAGE NOISE REDUCTION FOR TEST CYLINDER
                   (AVERAGE AND 95% CONFIDENCE LIMITS, TRIM LOSS
                   FACTOR = 1.0, TOTAL STRUCTURAL LOSS FACTOR
                   LIMITED TO 0.15 MAXIMUM)
The computer program assumes that no noise is transmitted
through the ends of the cylinder, since such contributions are
not usually important in aircraft. Furthermore, because of the
directivity characteristics of propeller noise, the noise levels
on the end plates of the test cylinder would be low when the
cylinder was exposed to the propeller excitation. Thus, noise
transmission through the end plates would be negligible in the
propeller noise test. The contribution becomes significant
only for reverberant field excitation.

The agreement between measured and predicted noise reductions is
not as good as was the case for propeller noise excitation. The
discrepancy between predicted and measured noise reductions at
high frequencies was observed in previous data [7] where it was
believed to be due to flanking paths through exposed stiffeners.
There are no flanking paths of this type in the present test
model. Two possible explanations for the discrepancy are (a)
other flanking paths are present, and (b) the analytical model
over-estimates the influence of the sidewall treatment.


The noise transmission measurements were repeated with the
fiberglass treatment on the end plates increased from a thick-
ness of 1*3 cm (0.5 inch) to 3.1 cm (2 inches). The resulting
change in measured space-average noise reduction is shown ir
Figure E-23 which contains spectra associated with the two
treatments. Figure E-23 contains corresponding predicted noise
reduction spectra. The two figures show somewhat different
trends with the predictions giving an increase in noise reduc-
tion in the frequency range 315 to 1250 Hz whereas the increase
in measured noise reduction occurs mainly at frequencies above
800 Hz.


The predicted spectra in Figure E-24 are influenced directly by
the analytical model for the fiber glass material on the end
plates. Figure E-25 compares the acoustic loss factors computed



                             E-35
      70
                 MEASURED VALUES: 1.3 CM TRIM ON END PLATES
                 MEASURED VALUES: 5.1 CM TRIM ON END PLATES

      60




      50

m
o



CJ

a
LU
ct:
      30
LLJ
tn
Â»â€”*
E3
2



      20        A

      30




           63   125    250     500   1000    2000   4000      8000
                 ONE-THIRD OCTRVE BOND CENTER FREQUENCY, â€¢ HZ



      FIGURE E-23.   MEASURED NOISE REDUCTIONS FOR CYLINDER WITH
                     ^DIFFERENT THICKNESSES OF FIBERGLASS BATTS
                      ON END PLATES


                                E-36
     70
               PAIN PREDICTION:     1.3 CM TRIM ON END PLATES
               PAIN PREDICTION:     5.1 CM TRIM ON END PLATES



     60




     50


en




     30
LU
to




     20




     10




          63   125    250     500       1000   2000    UOOO        8000
                ONE-THIRD OCTflVE BRND CENTER FREQUENCY,      HZ




      FIGURE E-24., PREDICTED NOISE REDUCTION FOR CYLINDER WITH
                    DIFFERENT THICKNESSES OF FIBERGLASS BATTS
                    ON END PLATES


                             E-37
          J



        0.5




                                                      /
        0.2                                               N




                                       -V
                                                              \
oc                                                             \
Q                                                                  I




                                                  \\
                                                                   X
                                            .^
Â§ o.-'                                                                 \
Li-
en
                                     /                                     \
                                                                               \
                                                                                   N
m
S      0.05                                                                             A
C_)
r~i
tâ€”
to
| 0.02
                                                          \                    ,
                                                                                       A]\\ \\
cr                                                                                           \\

       0.01
                                                                                                  V
                                                                                                  \\
              â€”â€”â€”â€”â€” i .3 CM TR IM ON E:ND PL/^TES                                                  \\
                                                                                                   Vk



                                                                                                        \
      0.005         i
                      .1 CM TR IM ON E.ND PL/^TES



      0.002



      n nm
          10       20        50     100     200      500                       1000      2000           5000   10000
                                                  FREQUENCY, HZ



          FIGURE E-25. PREDICTED ACOUSTIC LOSS FACTORS FOR CYLINDER
                       WITH DIFFERENT THICKNESSES OF FIBERGLASS BATTS
                       ON END PLATES




                                          E-38
for the interior of the cylinder for the two end plate treat-
ments. The results show that a resonance-type effect predicted
for the trim is shifted down in frequency from 1600 Hz for the
1.3 cm treatment on the end plates to 500 Hz for the 5.1 cm
treatment.

General Comments

This brief discussion of validation studies for the analytical
model has shown fairly good agreement between predicted and
measured sound levels in a cylinder exposed to propeller noise
excitation. The discussion has also identified several items
for future study in order to improve the analytical model. For
the propeller noise pressure field, the procedure for estimating
pressure reflection effects should be reviewed. Also, the ana-
lytical model for relative phase between the upper and lower
grids should be validated.

The present analysis represents the first time that the sidewall
treatment has been incorprated as an integral part of the sound
transmission model. As such, the analysis makes a major step in
providing a comprehensive model for airplane interior noise.
The validation studies indicate that some improvements to the
sidewall treatment model are required in order to improve the
agreement between predictions and measurements. It is recom-
mended that these improvements be made.




                             E-39
  APPENDIX F

LIST OF SYMBOLS
                       LIST OP SYMBOLS

A             Cylinder surface area, used in Eq.(4).
         or
A             Interior (cylinder & floor) surface area, used in
              conjunction with structural/acoustic coupling
              function f'(n,r)

A1            Transmitting area of cylinder without trim

A             Exterior cylinder surface area

A             Transmitting area of cylinder with trim
    T/

(A + A 1 )    Total transmitting area of cylinder, floor to floor

Auri          Amplitude of Fourier component of blocked propeller
              pressure signature at propeller harmonic H and grid
              location m = (k,l), see Eq.(43)

Am            Amplitude of Fourier component of free field propel-
              ler pressure at harmonic H and grid location m=(k,Â£)

a             Radius of cylinder

.m
aâ„¢            Fourier series coeffficient of propeller pressure,
    H
              for harmonic H at location m; see Eqs. (2?),(29)

am/2          Mean propeller pressure amplitude at location m
              (defined in Eq.(28))

arctan n \
        l     Functions defined in Section 3.3, Eq.(17), et seq
arctan I

B        -    Number of propeller blades

                                                            N"R
BPF           Propeller blade passage frequency (Hz); BPF = -


                                F-l
                            LIST OP SYMBOLS
                              (Continued)

bn,br            Functions defined in Section 3.3, Eq.(17) et seq

bun              Fourier series coefficient of propeller pressure
                 for harmonic H at location m; see Eqs.(27),(29)

C(J)             Function defined in Eq.(76)

                                          fZ
Cin(z)           Cosine integral; Cin(z) =J (l-cost)dt/t

 "Q T*   S T**
^Mn^Mn           Floor and shell generalized coordinates for
                 structural mode r = (M,N); see Eqs.(46)-(49)

Cpbl (x| xf ;w )    Cospectral density function of the blocked
                   exterior pressure field

Cp(x| x';co)     Cospectral density function of the exterior
                 pressure field

CW,GW,CW         Trim parameter, derived from the trim transfer
                 matrix, Eq.(A.B); Cw = C* + iC^

C x (^,o))C (^,co) Cospectral density functions of the exterior
           y
                   pressure field in the axial and transverse
                   directions respectively; see Eq.(60)

c0               Speed of sound in air

cn,cr            Functions defined in Section 3Â«3, Eq.(17) et seq

GW               Constant percentage bandwidth parameter, where
                 Au = c a) [c = 0.232 for one-third octave bands']
                       to    w




                                   F-2
                        LIST OP SYMBOLS
                          (Continued)

Dnr         Function defined in Section 3-3, Eq.(17) et seq

E[      ]   Expected value of a function

f'(n,r)     Interior structural/acoustic coupling factor; see



f ' (n,r)=f ' (qi, r) Interior structural/acoustic coupling factor
                    including effect of trim factor T, , see
                  Eq.(52)

f..         Frequency of propeller 1st harmonic; f^ = 1/T    =
            BPF

fjj         Frequency of propeller harmonic H; f    = Hf^

f            Acoustic/structural coupling factor in axial
            direction; see Eq.(57)

gn,gr       Functions defined in Section 3-2, page 3-11

H           Propeller harmonic order, used as superscript to
            denote functions evaluated at frequency <*)â€ž
                                                       ii

i            Acoustic mode number counter for fuselage cross-
            section modes, associated with mode n =(q,i)


I1I2I        Integrals defined in Equations (63) and (70)-(73)

j           Circumferential location on fuselage wall, 6., a
                                                        J
            boundary point at which the acoustic eigenvector
            is evaluated (see Fig.C-2)



                               F-3
                               LIST OP SYMBOLS
                                 (Continued)

j-2., (o>)          Structural joint acceptance function in axial
                    direction

j2T(co)             Structural joint acceptance function in
                    circumferential direction

J 2 (w)             Structural joint acceptance in axial and
                    circumferential directions; jÂ£(w) = Jr/^1
                    =
                      JM^) Ji.T((JL)); see Eq.(58)
    2
        rev
jr            (w)   Joint acceptance for reverberant/diffuse
                    excitation

<j (u)>             Joint acceptance for reverberant excitation
                    averaged over structural modes resonant in band Aw

k                   Acoustic wave number, k = 2fr/A
        or
k                   Axial non-dimensional   coordinate for grid point;
                    see Figure E-4

L                   Fuselage structure length

L                   Floor width (wall to wall)
 P

Â£                   Circumferential non-dimensional   coordinate for
                    grid point; see Figure E-^J)

In ,ln              Functions defined in Section 3.3, Eq.l? et seq

M                   Number of axial half-wavelengths for structural
                    mode r = (M,N)
                       LIST OP SYMBOLS
                         (Continued)

Mr          Generalized modal mass, for structure mode r

m = (k,Â£)   Grid point on surface of cylinder used for
            propeller noise predictions; see Figure E-4
     or
m           Average surface mass/unit area of cylinder

N           Structural mode counter, associated with mode
            r = (M,N)
     or
N           Propeller rpm

Nn,Nr       Number of acoustic modes or structural modes in
            frequency band Aw

n           Symbolizes acoustic mode n = (q,i)
     or
n           Number of circumferential wavelengths (or
            transverse half-wavelengths) in fuselage
            shell (or floor); see Eqs.46-49.

n*          Number of terms in displacement series for
            fuselage shell (or floor)

nb,n^       Number of boundary points on the fuselage shell
            (or floor) at which the acoustic eigenvectors are
            defined

n           Modal density of acoustic modes

nr          Modal density of structural modes




                              F-5
                                   LIST OP SYMBOLS
                                     (Continued)

P(wn)                  Probability distribution function for u> in Aw

p(u)n)                 Probability density function for CD in Aw

p         (x,t)        Exterior pressure over the blocked (immobile)
                       fuselage

<p
     bl>               Band-limited mean square blocked pressure

<pf(Â£,<jj)>            Interior mean square pressure at location 1
                  L/



<p? >                  Space-averaged band-limited mean square interior
         1 S)t
                       pressure

<
pfG >=â€¢
     5 U
        +â€¢             Space-averaged band-limited mean square exterior
           3
                       pressure for a reverberant field

<P 2 >                 Space-averaged band-limited mean square modal
  n s^ u
                       pressure, for nth mode in interior volume V

Qu                     Function defined in Section 3.2. En.(12)
    rt

q                      Number of axial half-wavelengths for acoustic mode
                       n = (q,i)

r                      Symbolizes structural mode r = (M,N)

r                      Radial distance from center of fuselage cylinder
                       to the axis of rotation of the propeller.




                                         F-6
                           LIST OP SYMBOLS
                             (Continued)

R    (x|x';to)    Average cross correlation of the exterior
                  blocked pressure over the fuselage

S                Absorbing surface area of fuselage sidewall

Se           Absorbing surface area on each end surface
             (bulkhead)

Sp(w)        Power spectral density of exterior pressure

Spb-,(w)     Power spectral density of exterior blocked
             pressure

Spbl(x|x';w)   Cross spectral density of exterior blocked
               pressure
Si(z)        Sine integral; Si(z) = \z sint.dt/t
                                      o

t                time

T                Period of rotation of propeller; T = 60/N

T .T-,           Period of propeller noise signature; T = T    =
                 (BPF)"1 = T/B

u                In-plane axial displacement of cylinder wall (or
             floor)

V            Volume of cavity

v            Circumferential (or transverse) displacement of
             cylinder wall (or floor)

V/dlss       Power dissipated on the cabin walls


                                  F-7
                         LIST OP SYMBOLS
                           (Continued)

W.            Net power inflow

" n (03)      Spectral density of power radiated by structure
              into interior acoustic space

..3.,D S(w)   Spectral density of power absorbed on inner wall
              of the space from interior acoustic field

w             Cylinder wall (or floor) normal displacement

x             Transverse coordinate; see Figure 1

x             Location on exterior surface of fuselage

xm            Location of grid point on exterior surface of
              fuselage

X
    1X2X3     Local coordinate systems; see Figure E-1!



y             Vertical coordinate, relative to fuselage
              centerline (see Figure 1)

z             Axial coordinate, relative to forward end of the
              fuselage structure (of length L); see Figure E-4

z             Axial coordinate for grid point k, see Figure E-4

z             Location of propeller relative to the forward end
              of the fuselage structure (of length L); see
              Figure 1)




                                 F-8
                        LIST OP SYMBOLS
                          (Continued)

            Band average absorption coefficient

            Incidence angle between propeller and location x ;
            see Figure 2 (in degrees)

            Grid spacing for propeller noise predictions

AA = A2     Area associated with each grid point; see Figure E--

Aco( radians/sec) Frequency band of width Aw = c w
                                                 0)
                  n<Aw symbolizes modes resonant below band
                  neAco symbolizes modes resonant inside band
                  n>Au symbolizes modes.resonant above band

6( )        Delta function

en = V//v<j>^dv Acoustic mode normalization factor

e           Acoustic mode normalizing -factor in axial direction
             (see Eq.C.ll)

t,          Transverse coordinate; see Section 3-6

n           Acoustic mode loss factor
    n

n           Structural mode loss factor
    r

n'          Structural loss factor, including damping due to
            trim; Eq.(B2)


n''         Internal radiation loss factor, due to closely
            coupled structural and acoustic modes; Eq.(83)



                               F-9
                                    LIST OP SYMBOLS
                                      (Continued)

nn                       Average one-third octave band acoustic mode loss
                         factor

n -L = n'
        -P
           +TI'
              JL
                 ' +nexj;       Average one-third octave band structural mode
                               loss factor

              uc
nr                       Average one-third octave band structural loss
                         factor

 â€¢vi *a *-3
nr                       Average one-third octave band radiation loss factor

 int               ext
               n    d    Average one-third octave band internal and external
                         radiation loss factors defined after Eq. (19)

                         Angular coordinate, relative to fuselage bottom
                         centerline; see Figure 1

                         Angular coordinate for grid location (k,Â£ )

                         Angle at which fuselage shell/floor joint is
                         located

                         Angle 6 for point j on fuselage wall, a boundary
                         point for the acoustic eigenvectors

               j         Angles defining mid-points between boundary point j
                         and adjacent boundary points

                         Axial coordinate; see Section 3.6
               or
                         Conductance for trim on end surface of cylinder
                         interior



                                           F-10
                                LIST OF SYMBOLS
                                  (Continued)

|                      Interior cavity location

Â£                  Conductance for trim on cylinder (fuselage) sidewall

p                  Density of air inside the cylinder

p                  Density of air outside the cylinder

T                  Time delay for cross-correlation
         or
T                  Acoustic transmission coefficient for diffuse field
                   excitation; T = T â€ž + T^
                                      i      R

if                 Field incidence transmission coefficient for mass
                   controlled panels; defined in Eq.(20)
             /2pc\ 2
T        =
 mL          \ moo /    Mass law sound transmission coefficient

t                  Trim transmission coefficient, defined in Eq.(A.22)

     p             Resonance transmission coefficient for diffuse
                   field, defined in Eq.(19)

     ^(1)
     (j            Generalized mass for two-dimensional acoustic mode
                   i, defined in Appendix C

f>                 Angular position of propeller hub relative to
                   fuselage bottom centerline; see Figure 2

j>H                Phase of Fourier component of propeller pressure
                   signature at propeller harmonic H and grid location
                   m = (kÂ£)


                                          F-ll
                                  LIST OP SYMBOLS
                                    (Continued)

                             Mode shape, or eigenfunction, of the nth mode
                             cf the cavity at location Â£

$^(6.)                 Mode shape of ith acoustic mode of the fuselage
                       cross-section evaluated on the fuselage wall at
                       location j, angle 6.
                                          J



^G(r,H)                Generalized modal forcing function due to propel-
                       ler noise, mode r at propeller harmonic H; see
                       Section 3.4

     TO   â€”
ijj (x)                Mode shape, or eigenfunction, of the rth mode of the
                       structure, at location x

i|>p(z,,x)             Floor displacement in structure mode r

     1Â°
ijjs (z,G)             Fuselage shell displacement in structure mode r

w                      Angular frequency (rads/sec)

a)                     Angular frequency of propeller harmonic H
     H

to                     Acoustic mode resonance angular frequency

w                      Structure mode resonance angular frequency

<             >        Band-limited, space-averaged and time-averaged value
              S y T>




                                         F-12
 1. Report No.                             2. Government Accession No.                  3. Recipient's Catalog No.
   NASA CR-3813
 4. Title and Subtitle                                                                  5. Report Date
                                                                                              July 1984
    PROPELLER AIRCRAFT INTERIOR NOISE MODEL
                                                                                        6. Performing Organization Code


7. Author(s>                                                                            8. Performing Organization Report No.
    L. D. Pope, E. G. Wilby, and J. F. Wilby                                                 5058

9. Performing Organization Name and Address                                             10. Work Unit No.

    BOLT BERANEK AND NEWMAN INC.
    21120 Vanowen Street                                                                11. Contract or Grant No.
    Canoga Park, CA 91303 .                                                                  NAS1-15782
                                                                                        13. Type of Report and Period Covered
 12. Sponsorina Agency Name and Address
                                                                                             Contractor Report
     National Aeronautics and Space Administration
     Washington, DC 20546                                                               14. Sponsoring Agency Code


 15. Supplementary Notes

      Langley Technical Monitor: William H. Mayes


 16, Abstract

      An analytical model has been developed to predict the interior noise of
      propeller-driven aircraft. The fuselage model is that of a cylinder
      with a structurally-integral floor. The cabin sidewall is stiffened by
      stringers and ring frames, and the floor by longitudinal beams. The
      cabin interior is covered with a sidewall treatment consisting of layers
      of porous material and an impervious trim septum. Representation of the
      propeller pressure field is utilized as input data in the form of the
      propeller noise signature at a series of locations on a grid over the
      fuselage structure. Results obtained from the analytical model are
      compared with test data measured by NASA in a scale model cylindrical
      fuselage excited by a model propeller.




 17. Key Words (Selected by Author(s))                            18. Distribution Statement

      Aircraft Interior Noise
      Propeller Noise                                                  Unclassified - Unlimited
      Cylinder Noise Reduction
      Acoustic Power Flow                                              Subject Category 71

 19. Security Classif. (of this report)      20. Security Classif. (of this page)          21. No. of Pages   22. Price*

      Unclassified                             Unclassified                                      166                 A08
'For sale by the National Technical Information Service, Springfield. Virginia 22161.

                                                                                                              NASA-Langley, 1984
```
