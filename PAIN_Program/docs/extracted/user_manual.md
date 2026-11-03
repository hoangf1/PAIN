# NASA-CR-172425 user manual (OCR extract)

> Machine-extracted text from the corresponding PDF. OCR errors are expected; prefer the PDF for authoritative wording.

```text
    NASA Contractor Report 1 7 2 4 2 5


     A N T E B I O R N O I S E BCCZL: CSEII'S E A E U A L FOB
     C C B P E T E R F R O G E A L E i n a l B e C O K t (Eclt,
     E e r a n e k , and l i e u r a n , Inc.)   55     E       C S C L 20A              Unclas
.
    Propeller Aircraft Interior /n/-7/
    Noise Model - Users' Manual 3 - 8 1 3 ~ -
    for Computer Program



    E.G.Wilby and L.D.Pope




    Bolt Beranek and Newman Inc.
    Canoga Park, CA 9 1 3 0 3




    Contract NAS 1 - 1 5 7 8 2
    JANUARY1985 .

                                                                                                      I
                                                      Date for general release   January 3 1 , 1987


    National Aeronautics and
    Space Administration
    Langley Research Center
    HamDton Vlrglnia 23665
                          TABLE OF CONTENTS



Section                                                                Page

1.0   SUMMARY .....................                                      1



2.0   INTRODUCTION ..................                                    2

3.0   MODELS                               0




4.0   OVERALL PROGRAM DESCRIPTIONS.                  e                  15

5.0   INPUT DATA      ...................                               113
      5.1 Program CYL2D.            ...............                     18
            5.1.1 I n p u t Data. . . . . . . . . . . . . .             18
            5.1.2     O u t p u t F i l e , Tape 11. .     . . .        18
            5.1.3 P r i n t e d Output. . . . . . . . . . . .           18
      5 . 2 Program MRP. . . . . . . . . . . . . . . . .                19
            5.2.1     I n p u t Data. . . . . . . . . . . . . .         19
            5.2.2     O u t p u t F i l e Tape 7 . . . . . . . . . .    25
            5.2.3 P r i n t e d Output. . . . . . . . . . . .           25
      5.3 Program MRPMOD . . . . . . . . . . . . . . .                  26
            5.3.1 I n p u t Data. . . . . . . . . . . . . .             26
            5.3.2     Input Files . . . . . . . . . . . . .             27
            5 . 3 . j O u t p u t F i l e , Tape 9 . . . . . . . . .    27
            5.3.4     P r i n t e d Output. . . . . . . . . . . .       28
      5.4 Program PAIN . . . . . . . . . . . . . . . .                  28
            5.4.1 I n p u t Data. . . . . . . . . . . . . .             28
            5.4.2     Input Files . . . . . . . . . . . . .             35
            5.4.3 P r i n t e d Output. . . . . . . . . . . .           35




                                   -i-
                                TABLE OF CONTENTS
                                    (Continued)

    Section                                                               Page

    6.0   CONTROL CARDS FOR EXECUTING THE PROGRAM             .       . . 38
          6.1 C o n t r o l C a r d s and Data f o r Program CYL2D  . . . 39
          6.2    C o n t r o l Cards a n d Data f o r Program MRP . . . . 40
          6.3                                                         . . 44
                 C o n t r o l C a r d s and Data f o r Program MRPMOD.
          6.4    C o n t r o l Cards a n d Data f o r Program PAIN. . . . 45


    REFERENCES                                                             47

    APPENDIX A    -                                                        A- 1
    LIST OF SYMBOLS




I                                      -11-
                                  LIST OF FIGURES



Figure                                                                          Page



1.   P r o p e l l e r A i r c r a f t I n t e r i o r N o i s e Model. ...       3

2.   P r o p e l l e r and F u s e l a g e S u r f a c e P o i n t Geometry .     4

3.                                               . ..
     G r i d Used f o r P r o p e l l e r N o i s e P r e d i c t i o n s         5

4.   Flow Chart f o r Programs . . . . . . . . . . . .                            17
1.0     SUMMARY

A computer program e n t i t l e d P A I N ( a n acronymn f o r P r o p e l l e r
-
Aircraft -
         I n t e r i o r N o i s e ) h a s been d e v e l o p e d t o p e r m i t c a l c u l a t i o n
of t h e sound l e v e l s i n a m o d e l of a c a b i n of a p r o p e l l e r - d r i v e n
a i r p l a n e . The model f u s e l a g e i s a c y l i n d e r w i t h a s t r u c t u r a l l y
i n t e g r a l f l o o r . The c a b i n sidewall and f l o o r a r e s t i f f e n e d by
r i n g frames, s t r i n g e r s and f l o o r beams of a r b i t r a r y c o n f i g u r a -
t i o n s . The c a b i n i n t e r i o r i s c o v e r e d w i t h a t r i m ( i . e . , i n s u l a t i o n
w i t h a l i n i n g ) t o i n c r e a s e t h e s i d e w a l l sound i s o l a t i o n a n d
p r o v i d e a b s o r p t i o n i n t h e cabin.

T h e p r o p e l l e r n o i s e of concern i s a c t u a l l y a s e r i e s o f t o n e s t h a t
o c c u r a t t h e b l a d e p a s s a g e f r e q u e n c y a n d a t i n t e g r a l m u l t i p l e s of
t h a t f r e q u e n c y ( i . e . , a t i t s h a r m o n i c s ) . The program permits t h e
c a l c u l a t i o n of t h e s p a c e - a v e r a g e i n t e r i o r sound l e v e l s f o r t h e
f i r s t t e n (10) h a r m o n i c s of a p r o p e l l e r ( o f any d e s i g n ) r o t a t i n g
alongside t h e fuselage.

The i n p u t data r e q u i r e d by t h e program i n c l u d e t h e m e c h a n i c a l and
a c o u s t i c a l p r o p e r t i e s of t h e f u s e l a g e s t r u c t u r e a n d s i d e w a l l t r i m .
Also, t h e p r e c i s e p r o p e l l e r n o i s e s i g n a t u r e must be d e f i n e d on a
grid t h a t lies i n the fuselage skin.                         The p r o p e l l e r d a t a h a v e t o
b e g e n e r a t e d w i t h a p r o p e l l e r n o i s e p r e d i c t i o n program f o r
example, t h e NASA Langley ANOPP program [l]).
2.0     INTRODUCTION

The p r e s e n t program mechanizes a n a n a l y t i c a l model p r e s e n t e d
i n Reference [2].        D e t a i l s of t h e u n d e r l y i n g t h e o r y on w h i c h
t h i s program i s b a s e d are a v a i l a b l e i n t h a t r e p o r t .


The two primary e l e m e n t s of t h e i n t e r i o r n o i s e model a r e t h e
f u s e l a g e a n d t h e p r o p e l l e r ( F i g s . 1 and 2 ) . The f u s e l a g e
c o n s i s t s of a c y l i n d e r s t i f f e n e d by r i n g frames a n d s t r i n g e r s ,
and a f l o o r t h a t i s s t r u c t u r a l l y a n i n t e g r a l p a r t of t h e
f u s e l a g e . The c a b i n s p a c e i s t h e volume a b o v e t h e f l o o r . The
i n t e r i o r s u r f a c e of t h e c a b i n ( s i d e w a l l ) i s f i n i s h e d o u t w i t h
a t r i m c o n s i s t i n g o f i n s u l a t i o n c o v e r e d w i t h a l i n i n g . The
p r o p e l l e r r o t a t e s a b o u t a n a x i s p a r a l l e l t o t h e c e n t e r l i n e of
the fuselage.               The model c a n b e u s e d t o p r e d i c t t h e s p a c e
a v e r a g e sound l e v e l s i n t h e c a b i n s p a c e f o r each of t h e
v a r i o u s harmonics of t h e p r o p e l l e r ( u p t o a maximum of t e n
 (10) h a r m o n i c s ) .

T h e p r e s e n t model works w i t h t h e p r e s s u r e time h i s t o r i e s ( s i g -
n a t u r e s ) as d e f i n e d o v e r t h e f u s e l a g e a t a number of c l o s e l y
s p a c e d p o i n t s on a g r i d t h a t l i e s i n t h e f u s e l a g e s k i n         ,



( F i g . 3 ) . T h e p r e s s u r e s i g n a t u r e s a r e i n p u t as F o u r i e r s e r i e s
t h a t d e f i n e t h e a m p l i t u d e s and phases o f e a c h of t h e h a r m o n i c s
of t h e p r o p e l l e r ( a t e a c h l o c a t i o n on t h e g r i d ) .

The f u s e l a g e s t r u c t u r a l modes are d e v e l o p e d f o r t h e c a s e of a
s t i f f e n e d cylinder with a f l o o r p a r t i t i o n .         The s t r u c t u r a l
p r o p e r t i e s of t h e c y l i n d e r a n d f l o o r a r e r e q u i r e d as i n p u t
d a t a . The s t r u c t u r a l modes a r e d e s c r i b e d by t h e computed
r e s o n a n c e f r e q u e n c i e s and mode s h a p e s , a n d by a s s o c i a t e d
s t r u c t u r a l loss f a c t o r s . The l o s s f a c t o r s of t h e modes of a
bare f u s e l a g e must b e i n p u t and must come f r o m measurements
 ( o r b e e s t i m a t e d ) . When t r i m i s i n s t a l l e d on t h e s i d e w a l l ,
t h e s t r u c t u r a l l o s s e s i n c r e a s e due t o t h e trim's p r e s e n c e
a g a i n s t t h e s i d e w a l l and t h i s i s computed f o r t h e p a r t i c u l a r
t r i m installation.                                -2-
N




          0
          E



          p?
          -
          0
          p?
          w
          c
          -
          Z

          t
          a
          p?
          u
          -ap?
          w
          A
          A
          w
          a.
          0
          &
          n




    -3-
            I                 A




                                        X




                                        -x = ( a , 8, z ) = Location of Free
                                            m                     Field Prediction
                                                                  Point
                                                      ,4, z       = Propeller Position
                                                ('P           P



            Y




FIGURE 2.       PROPELLER AND FUSELAGE SURFACE P O I N T GEOMETRY




                                  -4-
              ORIGINAL PAGE SS
              OF POOR QUALITY

                        v)
                        w
N                       L




                                 N
                                 X




                                     0
                                     z




                                     m
                                     w




    /




        -5-
The a c o u s t i c modes o f t h e c a b i n s p a c e a r e s i m i l a r l y d e f i n e d by
t h e r e s o n a n c e f r e q u e n c i e s , mode s h a p e s , and l o s s f a c t o r s .   The
a c o u s t i c l o s s f a c t o r s must be i n p u t f o r a bare f u s e l a g e b u t
a r e c a l c u l a t e d when a c a b i n t r i m i s I n s t a l l e d .

The e f f e c t s i n t r o d u c e d by t h e t r i m a t a g i v e n f r e q u e n c y a r e
computed u s i n g t h e v a l u e s of t h e wave impedance and complex
a c o u s t i c wavenumber i n t h e i n s u l a t i o n , and t h e t r i m l i n i n g
s u r f a c e weight and l o s s f a c t o r .




                                                   -6-
3.0     MODELS

One c a n b e g i n t o c o n s t r u c t an i n p u t card p a c k a g e o n c e t h e
b a s i c s i z e of t h e f u s e l a g e i s known a n d t h e l o c a t i o n of t h e
p r o p e l l e r d e f i n e d . The o v e r a l l geometry must b e f i x e d s o t h a t
t h e g r i d t h a t w i l l l i e In t h e f u s e l a g e s k i n ( F i g . 3 ) c a n be
l o c a t e d . The g r i d i s u s e d f o r s p e c i f i c a t i o n of t h e p r o p e l l e r
n o i s e e x c i t a t i o n . The p r o p e l l e r - i n d u c e d p r e s s u r e s i g n a t u r e a t
e a c h l o c a t i o n on t h e g r i d i s r e q u i r e d , a n d a p r o p e l l e r n o i s e
p r e d i c t i o n program s u c h as t h e N A S A Langley ANOPP program [ l ]
w i l l h a v e t o b e u s e d t o make t h e s e p r e d i c t i o n s . O b v i o u s l y ,
t h e p r o p e l l e r d i a m e t e r , rpm, number of b l a d e s , b l a d e s h a p e s ,
a i r c r a f t f o r w a r d speed, e t c . , w i l l be needed f o r t h e s e c a l c u -
l a t i o n s . The program PAIN uses f r e e - f i e l d d a t a as i n p u t a n d a
c o e f f i c i e n t i s applied t o the free-field amplitudes i n a crude
a t t e m p t t o model t h e s u r f a c e r e f l e c t i o n s c a u s e d by t h e f u s e -
lage.         I f a p r o p e l l e r n o i s e p r e d i c t i o n program t h a t t a k e s i n t o
a c c o u n t t h e r e f l e c t i o n from a r i g i d c y l i n d e r l o c a t e d n e a r b y i s
used, t h e s u r f a c e r e f l e c t i o n c o r r e c t i o n s a p p l i e d i n t h e
p r e s e n t program c a n be removed a n d t h e new t y p e o f p r o p e l l e r
d a t a c a n b e i n p u t , j u s t as i s done a t p r e s e n t w i t h t h e
f ree-f i e l d d a t a .


After t h e p r o p e l l e r data a r e g e n e r a t e d , t h e r e m a i n d e r of t h e
i n p u t r e q u i r e m e n t s a r e a s s o c i a t e d w i t h t h e d e f i n i t i o n of t h e
f u s e l a g e s t r u c t u r e a n d t h e t r i m on t h e c a b i n s i d e w a l l .

The f o l l o w i n g i s a s t e p - b y - s t e p     procedure used t o parameterize
t h e i n t e r i o r n o i s e model:




                                                      -7-
         R e f e r r i n g t o F i g . 2 , d e f i n e t h e p r o p e l l e r hub p o s i t i o n a l o n g -
         s i d e t h e f u s e l a g e by t h e c o o r d i n a t e s ( r ,$ , z p ) .       The dimen-
                                                                            P
         SiOn rp i s t h e r a d i a l d i s t a n c e f r o m t h e c e n t e r o f t h e f u s e -
         lage c y l i n d e r t o t h e axis of r o t a t i o n of t h e p r o p e l l e r .
         $ d e f i n e s t h e a n g u l a r p o s i t i o n r e l a t i v e t o t h e bottom of t h e
         f u s e l a g e . The l o c a t i o n o f t h e p r o p e l l e r r e l a t i v e t o t h e
         f r o n t o f t h e c y l i n d e r i s g i v e n by z p . The b a s i c f u s e l a g e
         c o n f i g u r a t i o n i s f i x e d by t h r e e d i m e n s i o n s - - t h e c y l i n d e r
         l e n g t h L , r a d i u s a , and t h e p o s i t i o n o f t h e f l o o r as d e f i n e d
         by t h e a n g l e e o (see F i g s . 1 a n d 3 ) .

    2)   T h e g r i d u s e d f o r t h e p r o p e l l e r n o i s e p r e d i c t i o n s must n e x t
         be l o c a t e d i n t h e s k i n .         The g r i d i s d e f i n e d o v e r o n e - q u a r t e r
         of t h e p e r i p h e r y of t h e c y l i n d e r . Three c o o r d i n a t e s of
         c o n c e r n a r e t h e s o - c a l l e d ANOPP c o o r d i n a t e s ( x l , x 2 ,
         X3)     i n F i g . 3 . F o r p u r p o s e s of d e f i n i n g t h e c o o r d i n a t e s of
         t h e g r i d p o i n t s ( k , a ) , t h e c o o r d i n a t e x 1 , whose o r i g i n i s
         a t t h e p r o p e l l e r hub, w i l l a l w a y s p e n e t r a t e t h e f u s e l a g e
         p e r p e n d i c u l a r l y and t h a t p o i n t of p e n e t r a t i o n w i l l e s t a b l i s h
         t h e l i n e ( 2 = 1). The c o o r d i n a t e p o s i t i o n s a r e t h e n g i v e n b y
         t h e f o l l o w i n g r e l a t i o n s f o r k = 1, kma,, and R = 1, 10.




         where          R
                    x 1 = (rp-a) + a ( l - c o s [ ( R - 1 ) 1 ~ / 1 8 ] }

                    x       =   -a s i n [ ( R-1) .rr/181

                    xâ€™; = ( n a / 1 8 ) [ k p - k l

         k p i s t h e k i n d e x of t h e g r i d p o i n t ( k , R ) = ( k p , l ) ,            that
         i s , where t h e c o o r d i n a t e XI p e n e t r a t e s t h e f u s e l a g e . F o r
         example, f o r kmax = 1 6 as i n F i g . 3 , s e t t i n g k p = 8
         roughly c e n t e r s t h e g r i d l o n g i t u d i n a l l y a b o u t t h e p r o p e l l e r
         p l a n e . Note t h a t t h e v a l u e o f ( 1 ~ a / 1 8 ) . [ k - 13 c a n n o t




I
                                                                                P



                                                      -8-
     exceed z P '        S i m i l a r l y , t h e c h o s e n v a l u e of kmax s h o u l d b e
     s u c h t h a t ( ~ 1 8 x) [kmax-l] < L. T h i s w i l l a s s u r e t h a t a l l
     g r i d p o i n t s are on t h e c y l i n d e r .


3)   The p r o p e l l e r n o i s e a t e a c h l o c a t i o n (k, a ) w i l l be p e r i o d -
     i c w i t h p e r i o d T1 = BPF-'             where BPF i s t h e b l a d e p a s s a g e
     frequency

                                                    NB
                                      BPF =               ,

     where N i s t h e rpm and B i s t h e number o f b l a d e s .                     The p r o -
     p e l l e r n o i s e a t each l o c a t i o n o n t h e g r i d , o v e r t h e p e r i o d
     t = 0 t o T I , i s ( E q . ( 3 3 ) o f Ref. 2 ) .
                                   a( k , R )
                                                    ZfpQ (                    ,y).
                                                     03


             PC(k,a),tl        =   Yj-0         +               cos w H t -
                                                    H=l
     a L k , " ) / 2 i s j u s t t h e mean p r e s s u r e and i s of n o c o n c e r n .
     However, t h e two c o e f f i c i e n t s           Gk")   and @H ( k 3 R )must be
     d e f i n e d . F o u r i e r a n a l y s i s of t h e computed p r e s s u r e time
     h i s t o r i e s o v e r t h e b l a d e passage p e r i o d T i s n e c e s s a r y t o
                                                                     1
     p r o v i d e t h e f i r s t t e n (10) h a r m o n i c s . The c o e f f i c i e n t s pk
     and @H f o r e a c h p o s i t i o n ( k , R ) a r e g i v e n by E q s . (31) and
     ( 3 2 ) of Ref. 2 .

4)   The s t r u c t u r a l p r o p e r t i e s of t h e f u s e l a g e c y l i n d e r and
     f l o o r are required next.                   These data c o n s i s t of t h e
     f ol l o w i n g :


     a ) The e l a s t i c m o d u l i i E a n d P o i s s o n ' s r a t i o s v o f t h e
         materials composing t h e c y l i n d r i c a l s h e l l a n d t h e
         floor plate.




                                                -9-
b) The equivalent thicknesses t of the shell and of
   the plate. These are given by the formula

                 t = t i + -A S           *R
                                   d + R,

  where ti is the actual thickness of the skin of the
  shell (or the plate thickness), A s is the cross-
  sectional area of the stringers on the shell (or
  the longitudinally running floor beams), d is the
  spacing between stringers (or floor beams), AR is
  the cross-sectional area of the ring frames on the
  shell (or the transverse floor supports), and    is
  the spacing between rings (or floor supports). Both
  the shell and plate must have a constant thickness,
  and the cross-section is uniform along the length of
  the cylinder.

c) The bending rigidities of the stringers (or longitu-
   dinal beams) and the ring frames (or floor supports)
   divided by the spacings, 1.e.

                               Y               II    ring
           ?)s t r i n g e r               "),rame
   and

                                           ")  II    floor
                                                     s uppor t


   The area moments of inertia of the stiffeners I are
   to be computed about the centerline of the skin (or
   plate) to which they are attached. If the stiffeners
   are not identical or not equally spaced, typical o r




                                   -10-
         average v a l u e s should be used f o r t h e bending r i g i d i -
         t l e s / u n l t width.

     d ) The a v e r a g e s u r f a c e mass m(kg/m2) of t h e c y l i n d e r
         wall ( o r f l o o r p l a t e ) , i . e ,

                                        m = pt,

         where P i s t h e d e n s i t y of t h e m a t e r i a l a n d t I s t h e
         e q u i v a l e n t t h i c k n e s s a s d e f i n e d i n ( b ) above.

5)   Having d e f i n e d t h e s t r u c t u r a l p r o p e r t i e s of t h e f u s e l a g e
     c y l i n d e r , t h e modes of t h e f u s e l a g e a r e c a l c u l a t e d u s i n g
     d i s p l a c e m e n t s e r i e s (see [21, Appendix D). The s h e l l
     d i s p l a c e m e n t i n mode r i s of t h e f o r m

                                      n*



     f o r s y m m e t r i c o r a n t i s y m m e t r i c modes, and f o r t h e
     floor,


           ~r~ ( z , x= ) sin-M-n z           ;;C     cos-
                                                          n-nx    (or sin-)n-nx
                                        n=O                  LP                LP

     where M = number o f l o n g i t u d i n a l h a l f - w a v e l e n g t h s (Max 1 5 )
           n = number o f shell c i r c u m f ' e r e n t i a l waves (Max 1 4 )
                    o r number of h a l f - w a v e l e n g t h s i n f l o o r w i d t h
                    (Max 8).
             n * = number o f terms i n d i s p l a c e m e n t s e r i e s f o r s h e l l
                    or floor

     The s y m m e t r i c modes and a n t i s y m m e t r i c modes are c a l c u l a t e d
     s e p a r a t e l y , f o r t h e same r a n g e o f v a l u e s o f M and n.   The
     c y l i n d e r I s assumed t o be s u p p o r t e d a t b o t h e n d s by shear
     diaphragms.
                                                -11-
6)   Next come t h e g e o m e t r i c a l p r o p e r t i e s of t h e c a b i n space
     which a r e g i v e n e n t i r e l y by t h e c a v i t y l e n g t h L,,
     radius a, a n d t h e f l o o r a n g l e e o . It i s n o t n e c e s s a r y
     t h a t t h e c a v i t y l e n g t h be e q u a l t o t h e s t r u c t u r e l e n g t h L.
     A variable d is defined that is the difference i n the z
     c o o r d i n a t e s between t h e s t a r t o f t h e c a v i t y and t h e s t a r t
     of t h e s t r u c t u r e and i s p o s i t i v e i f L < L,.           Usually L
     w i l l b e e q u a l t o o r g r e a t e r t h a n L, and d w i l l be z e r o o r
     negative.

7)   There a r e c e r t a i n d a t a t h a t p e r t a i n t o t h e t r i m i n s t a l l a -
     t i o n , namely

     a ) The wave impedance of t h e i n s u l a t i o n




          a n d t h e complex a c o u s t i c wavenumber




          where

                                     k = 2a/Xm,

          and A m i s t h e a c o u s t i c w a v e l e n g t h i n t h e m a t e r i a l .

     b ) The t r i m l i n i n g mass per u n i t         area mt a n d t h e f l e x u r a l
          loss f a c t o r 'It of t h e l i n i n g .

     The wave impedance i s g i v e n by t h e a m p l i t u d e IWl . i n
     mks r a y l s and t h e phase 4 i n degrees.            The a t t e n u a t i o n
     c o n s t a n t a i s i n p u t i n dB/m and t h e a c o u s t i c wave-
     l e n g t h A m i n meters. The data are, of c o u r s e , f r e q u e n c y -
     d e p e n d e n t . They are read i n as a t a b l e a t o n e - t h i r d



                                             -12-
     o c t a v e band c e n t e r f r e q u e n c i e s .   I n t h e case of p r o p e l l e r
     n o i s e p r e d i c t i o n , t h e b l a d e p a s s a g e f r e q u e n c y and i t s
     h a r m o n i c s w i l l f a l l a t f r e q u e n c i e s s e t by t h e p r o p e l l e r
     s p e e d and number of b l a d e s .               I n such a c a l c u l a t i o n , t h e
     f r e q u e n c y bands h a v e no p u r p o s e o t h e r t h a n d e f i n i n g t h e
     frequencies f o r the data required f o r the t r i m .                            The
     i n s u l a t i o n p r o p e r t i e s needed a t t h e f r e q u e n c i e s of t h e t o n e s
     ( i . e . t h e BPF a n d i t s h a r m o n i c s ) a r e i n t e r p o l a t e d f r o m t h e
     i n p u t a t t h e band c e n t e r f r e q u e n c i e s . Data f o r a s t a n d a r d
     a i r c r a f t g l a s s f i b e r i n s u l a t i o n a r e g i v e n i n Appendix A of
     Ref. [2 3 .

8)   When t h e a c o u s t i c and s t r u c t u r a l modal d e n s i t i e s a r e l a r g e
     enough, t h e t r a n s m i s s i o n c a n be e x p e c t e d t o be d o m i n a t e d b y
     modal r e s p o n s e c l o s e t o t h e e x c i t a t i o n f r e q u e n c y . High
     f r e q u e n c y f o r m u l a t i o n s have been d e v e l o p e d i n R e f . [ 2 ] as a n
     a p p r o x i m a t i o n i n t h i s c a s e . These a p p r o x i m a t i o n s r e s u l t i n a
     c o n s i d e r a b l e s a v i n g i n computation t i m e .

     If t h e change f r o m low f r e q u e n c y t o h i g h f r e q u e n c y f o r m u l a -
     t i o n i s d e s i r e d a t and above a g i v e n f r e q u e n c y , t h i s f r e -
     quency m u s t be s p e c i f i e d i n Program PAIN. T h r e e o p t i o n s a r e
     available f o r this.

     a.     If t h e i n p u t f r e q u e n c y i s z e r o , t h e program estimates a
            change o v e r f r e q u e n c y b a s e d on t h e volume of t h e c a v i t y .
            The f r e q u e n c y i s t h e 1/3 o c t a v e band c e n t e r f r e q u e n c y i n
            which t h e f o l l o w i n g e m p i r i c a l v a l u e l i e s .


                                               4.1 coI
                                        f =                 Hz
                                                3m
             where V = c a v i t y volume (m 3 )
                    c 0 1 = I n t e r i o r s p e e d o f sound (m/sec).

       b.     I f t h e i n p u t f r e q u e n c y i s g r e a t e r t h a n t h e maximum
              1/3 o c t a v e band c e n t e r f r e q u e n c y o r p r o p e l l e r harmonic
              f r e q u e n c y , t h e low f r e q u e n c y f o r m u l a t i o n i s u s e d
              throughout.

       c.     I f any o t h e r f r e q u e n c y i s i n p u t , t h e program u s e s t h e
             h i g h f r e q u e n c y f o r m u l a t i o n a t and above t h e f i r s t
             1/3 o c t a v e band c e n t e r f r e q u e n c y i n which t h e i n p u t
             frequency lies.

I t should be noted that the high frequency formulation (expected
v a l u e ) i s c a l c u l a t e d a t a l l p o s s i b l e f r e q u e n c i e s and o u t p u t as
s u p p l e m e n t a r y i n f o r m a t i o n , a l t h o u g h n o t n e c e s s a r i l y v a l i d a t low
f r e q u e n c i e s . For t o n e t r a n s m i s s i o n , a bandwidth of 7 % has been
u s e d t o d e f i n e s t r u c t u r a l modes c l o s e t o t h e p r o p e l l e r harmonic.
4.0    OVERALL PROGRAM DESCRIPTIONS

The master ( m a i n ) program PAIN t h a t computes t h e i n t e r i o r
n o i s e l e v e l s u s e s data t h a t are g e n e r a t e d by f o u r a u x i l i a r y
programs.            One of t h e s e programs c a l c u l a t e s t h e a c o u s t i c modal
c h a r a c t e r i s t i c s of t h e cabin, two o t h e r programs t h e s t r u c -
t u r a l modal C h a r a c t e r i s t i c s of t h e f u s e l a g e , and a f o u r t h t h e
propeller noise f i e l d .

The a c o u s t i c modes are c a l c u l a t e d w i t h t h e program CYL2D.          The
o n l y i n p u t r e q u i r e d by CYL2D i s a s i n g l e card t o d e f i n e t h e
f l o o r a n g l e Bo.        The a c o u s t i c modes a r e d e t e r m i n e d f o r a two-
d i m e n s i o n a l c a s e ( i . e . q = 0 ) and a r a d i u s a = 1 meter. The
r e s o n a n c e f r e q u e n c i e s and mode s h a p e s are computed a n d t h e
mode s h a p e s n o r m a l i z e d f o r use by t h e main program.                   The
v a l u e s t h a t t h e e i g e n v e c t o r s t a k e on t h e p e r i p h e r y o f t h e
c a b i n a r e e x t r a c t e d and t h e n o r d e r e d i n s e q u e n c e of boundary
p o i n t s . A c o d e is u s e d t o i d e n t i f y s y m m e t r i c a n d a n t i -
s y m m e t r i c modes (1 = symmetric, 0 = a n t i - s y m m e t r i c ) .              These
c o n d i t i o n e d d a t a a r e w r i t t e n on a f i l e ( t a p e ) f o r r e c a l l by
t h e main program.                 Appendix C of R e f . [ 2 ] may be c o n s u l t e d f o r
more d e t a i l s of t h e c a l c u l a t i o n s p e r f o r m e d by CYL2D.

The s t r u c t u r a l modal data are p r o v i d e d by a program c a l l e d
MRPMOD whose o u t p u t i s a l s o t o a f i l e ( t a p e ) read by PAIN.
MRPMOD r e q u i r e s i n p u t d a t a i n t h e f o r m of c a r d s t h a t d e f i n e
t h e number of g e n e r a l i z e d c o o r d i n a t e s u s e d i n t h e s t r u c t u r a l
a n a l y s i s program, t h e maximum number of a x i a l h a l f w a v e s
( p r e s e n t l y M = 101, t h e number of g e n e r a l i z e d c o o r d i n a t e s
r e t a i n e d t o d e v e l o p a n a c c u r a t e s t r u c t u r a l mode s h a p e , t h e
c y l i n d e r l e n g t h , a n d f i n a l l y t h e c y l i n d e r a n d f l o o r masses p e r
u n i t o f area. I n a d d i t i o n , MRPMOD reads two f i l e s ( t a p e s ) w h i c h
a r e o u t p u t f r o m t h e f u n d a m e n t a l s t r u c t u r a l program MRP (MRP
s t a n d s f o r M. R . P e t e r s o n who d e v e l o p e d t h e o r i g i n a l a n a l y s i s
f o r t h e f l o o r p a r t i t i o n e d c y l i n d e r ) . The program MRP reads
d a t a cards t h a t d e f i n e t h e p r o p e r t i e s of t h e s h e l l a n d f l o o r
p l a t e m a t e r i a l s , masses p e r u n i t of area, s t i f f e n e r b e n d i n g
r i g i d i t i e s , and a l p h a m e r i c i n f o r m a t i o n t h a t d i r e c t s t h e
p r o g r a m ' s c a l c u l a t i o n s and o u t p u t . MRP must be r u n
twice--once f o r t h e s y m m e t r i c modes and o n c e f o r t h e a n t i -
symmetric modes. The two f i l e s ( t a p e s ) c r e a t e d by t h e s e r u n s
a r e read b y MRPMOD.                  The f i l e s ( t a p e s ) c o n t a i n t h e computed
mode s h a p e s and r e s o n a n c e f r e q u e n c i e s . MRPMOD t a k e s t h e
o u t p u t from MRP, c a l c u l a t e s t h e g e n e r a l i z e d masses, r a n k
o r d e r s t h e modes by f r e q u e n c y , a n d s e l e c t s t h e most
s i g n i f i c a n t g e n e r a l i z e d c o o r d i n a t e s , t h a t i s , t h o s e needed t o
r e c r e a t e t h e s t r u c t u r a l mode shapes where r e q u i r e d i n P A I N .
T a b l e D-1 of Appendix D of R e f . [ 2 ] g i v e s a n example of MRPMOD
output.

T h e p r o p e l l e r n o i s e d a t a must be c a l c u l a t e d w i t h a p r o p e l l e r
n o i s e p r e d i c t i o n program, s u c h as ANOPP E l ] .          This a u x i l i a r y
program i s n e i t h e r p a r t n o r p a r c e l o f P A I N as a r e t h e programs
CYL2D, MRP, and MHPMOD.                     P r o p e l l e r n o i s e d a t a must p r e s e n t l y
b e i n p u t t o t h e main program as a card d e c k t h a t c o n t a i n s ( i n
a s e q u e n c e t o b e s p e c i f i e d e x a c t l y i n Sec. 5 ) t h e l o c a t i o n of
t h e g r i d p o i n t s ( k , R ) of F i g . 3 and t h e c o r r e s p o n d i n g f r e e -
f i e l d F o u r i e r a m p l i t u d e s and phases of e a c h p r o p e l l e r h a r m o n i c
a t each l o c a t i o n of t h e grid.

T h e programs C Y L 2 D a n d MRPMOD d o n o t c a l l any s u b r o u t i n e s .
MRP a n d PAIN e a c h has a l a r g e number of s u b r o u t i n e s .                  The f l o w
c h a r t t h a t f o l l o w s i n F i g u r e 4 shows t h e b a s i c s e q u e n c e o f
i n p u t m a n i p u l a t i o n , c o m p u t a t i o n , a n d o u t p u t i n t h e main a n d
a u x i l i a r y programs.




                                                  -16-
cn
I
a
a
c3
0
a
n
a
w
I-
3
n
2
0
0
w
cn
5
z
a
0
EW
I-
z
I-
LL
a
a
0
a
2    c
U
w
J
J
w
n
0
n




         -17-
5.0      INPUT DATA

The f o l l o w i n g i s a card-by-card           d e s c r i p t i o n of t h e i n p u t f o r
t h e programs CYL2D, MRP, MRPMOD, and t h e main program P A I N .
A l l i n p u t i s i n m e t r i c u n i t s , w i t h a n g l e s i n degrees.


5.1      Program CYL2D

5.1.1        Input Data

      Card       Columns       Format          Description

         1         1   - 10     F10.3           F l o o r A n g l e , e o (see F i g u r e 1 )
         2             1       6/7/8/9          End of F i l e

The program CYL2D r e q u i r e s t h e IMSL l i b r a r y s u b r o u t i n e s EIGRF,
LINV2F, VMULFF, VSRTR and VSRTU.

5.1.2        Output File, Tape 11

T h e o u t p u t f i l e , Tape 11, must b e c a t a l o g e d o r s t o r e d f o r i n p u t
t o program P A I N .         Tape 11 c o n t a i n s

      F1o o r Ang 1e
      L o c a t i o n s a t which e i g e n v e c t o r s a r e s p e c i f i e d
      F i r s t 20 e i g e n v a l u e s ( s y m m e t r i c a n d a n t i s y m m e t r i c combined)
      G e n e r a l i z e d masses
      E i g e n v e c t o r s f o r b o t h i n t e r i o r a n d boundary o c a t i o n s

5.1.3        Printed Output

      E i g e n v e c t o r l o c a t i o n s , f o r c y l i n d e r i n t e r i o r a n d boundary.
      E i g e n v a l u e s f o r f i r s t 20 modes ( s y m m e t r i c an1 a n t isymmet r i c
      combined) f o r c y l i n d e r w i t h u n i t r a d i u s o f 1 meter. G r a p h i c a l
      p r e s e n t a t i o n of e i g e n v e c t o r s .
      G e n e r a l i z e d masses and e i g e n v e c t o r s .
                                                 -18-
5.2       Program MRP

5.2.1       Input Data

      -
      Card Columns Format D e s c r i p t i o n


      1         1-80     20A4         T i t l e c a r d s ( a s many as r e q u i r e d ) .
                                      These a r e p r i n t e d d i r e c t l y on t h e
                                      output but - n o t on Tape 7 o u t p u t .

      2         1-33     A3           END


      3         1-10     A10      .   I N P U T DATA


      4         1-7      A7           GENERAL


      5         6-21     4A 4         F R E E L Y SUPPORTED
                                      Shear d i a p h r a g m s a t e n d s of c y l i n d e r .

               36-43     2A4          RIGID     o r HINGED
                                      J o i n t c o n d i t i o n f o r Floor-Cylinder
                                      Junction.
                                                                           . .
               66-80     3A4,A3       SYMMETRIC    o r ANTISYMMETRIC
                                      Symmetry a b o u t a v e r t i c a l a x i a l p l a n e
                                      o f t h e modes r e q u i r e d .

      6         6-20     E15.0        Angle 8, ( d e g r e e s ) a t which t h e f l o o r
                                      j o i n t i s l o c a t e d (0, = 0 i s t h e bottom
                                      centerline)      .
      7         6-10     I5           S t a r t i n g v a l u e of M = l I n t h e d i s -
                                      placement series.

              11-15      I5           F i n a l v a l u e o f M (Maximum no. = 1 5 )
                                      (Max.M x No. of e i g e n v e c t o r s -
                                                                              < 225)


                                          -19-
 Card     Columns   Format   Description

  7       16-20     15       I n c r e m e n t f o r M = 1. M = number o f
(Contd)                      l o n g i t u d i n a l half-wavelengths.

          2 1-25    I5       S t a r t i n g v a l u e of ns=O i n s h e l l
                             circumferential displacement series.

          26-30     I5       F i n a l v a l u e of ns f o r s h e l l
                             (Maximum n o . = 14).

          31-35     I5       I n c r e m e n t f o r ns = 1.
                             n s = no. of s h e l l c i r c u m f e r e n t i a l waves

          36-40     I5       S t a r t i n g v a l u e of np = 0 i n f l o o r
                             width displacement series.


          41-45     I5       F i n a l v a l u e of np f o r f l o o r (Maxi-
                             mum n o . = 8 ) .

          46-50     I5       I n c r e m e n t f o r np = 1.
                             n     = no.    of h a l f - w a v e l e n g t h s   in floor
                              P
                             width.


   8       6-10     L5       T = l o g i c a l v a l u e t r u e . S h e l l u and
                             v degrees of f r e e d o m i n c l u d e d .

          11-15     L5       Y = l o g i c a l v a l u e t r u e . F l o o r u and
                             v degrees of f r e e d o m i n c l u d e d .

          16-20     L5       F = l o g i c a l value false.                 No e x t r a
                             printing required.

   9       1-5      A5       SHELL.        S h e l l s t r u c t u r a l data.


  10       6- 20    E15.0    Ex(N/m2) Modulus of e l a s t i c i t y i n
                             â€˜the axial d i r e c t i o n .
                                 -20-
  -
  Card      Columns   Format Description

   10       21-35     E15.0   Ee (N/m2) Modulus of elasticity in
( Cont d)                     the circumferential direction.

            36-50     E15.0   u X Poisson's ratio


            51-65     E15.0   uB PoIssonts ratio


            66-80     E15.0   Gxe (N/m2> Shear modulus. For
                              isotropic materials, If G x e is blank,
                              it is computed using G = E/2(l+u)

  11         6-20     E15.0   Thickness of shell (m).  Includes
                              ttsmeared-outtt
                                            stiffener areas.

            21-35     E15.0   S h e l l mass/unit area (kg/m2)
                              includ ing   smeared-ou t   stiffene r
                              masses.

            36-50     E15.0   Radius of shell

            51-65     E15.0   Length of shell

  12         6-20     E15.0   Dis=[y]     -
                                            E (t3-ti3)
                                                 X
                                   stringer 12 (1-u2)
                                                       (Nom)

                              Additional bending rigidity of shell
                              stringers/stringer spacing.

            21-35     E15.0

                              Additional bending rigidity of shell
                              frames/frame spacing.
                              (Moments of inertia of stringers or
                              frames to be computed about shell
                              centerline)


                              -21-
-
Card   Columns   Format   Description

13      1-5      A5       PLATE        Floor s t r u c t u r a l d a t a

14      6-20     E15.0    Ex(N/m2) Modulus o f e l a s t i c i t y i n
                          t h e axial d i r e c t i o n

       21-35     E15.0    Ey (N/m2) Modulus of e l a s t i c i t y i n
                          the transverse direction

       36-50     E15.0    v X Poisson's r a t i o

       51-65     E15.0    L,    Poissonls r a t i o
                           Y.

       66-80     E15.0    Gxy   (N/m2) S h e a r modulus.    If b l a n k ,
                          i t i s computed u s i n g G = E / 2 ( l + v ) .

15      6-20     E15.0    T h i c k n e s s of f l o o r (m) I n c l u d e s
                          "smeared-out" s t i f f e n e r areas.

       21-35     E15.0    F l o o r m a s d u n i t area (kg/m2) i n -
                          c l u d i n g "smeared-outt1 s t i f f e n e r masses.

16      6-20     E15.0    D;~=    [y]long beam
                                                 floor    -
                                                              EX(t3-ti3)

                                                                  12(1-v2)
                                                                                (N.m)
                          Additional bending r i g i d i t y of longi-
                          t u d i n a l f l o o r b e a m s / f l o o r beam s p a c i n g .

                                           (t3-ti3)
       21-35     E15.0    D' =
                           YP
                              [y]floor - Y
                                 sumort         1
                                                      E

                                                          12(1-v2
                                                                          (Nom)

                          Additional bending r i g i d i t y of t r a n s -
                          verse f l o o r supports/support spacing.
                          (Moments o f i n e r t i a o f s t i f f e n e r s a r e
                          t o be computed a b o u t t h e f l o o r c e n t e r -
                          line)




                           -22-
-
Card   Columns   Format   Description

17      1-3      A3       END
                          End of I n p u t Data

                          The f o l l o w i n g c a r d s c o n t r o l t h e o p e r -
                          a t i o n s p e r f o r m e d by t h e program.

18      1-17     A10,A7   GENERATE M A T R I C E S


19      1-10     A10      CONSTRAINT


20      1-5      A5       SHELL


21      1-5      A5       PLATE


22      1-3      A3       END


23      1-5      A5       SOLVE


24      1-5      A5       PUNCH           O u t p u t s t o Tape 7.
                                          (Not Card Punch)

25      1-11     A l l    FREQUENCIES


26      1-12     A12      EIGENVECTORS


27      9-10     I2       20         Number o f e i g e n v e c t o r s
                          (Generalized Coordinates) t o be
                          o u t p u t (Maximum no. = 20, a n d
                          Max.M x No. of e i g e n v e c t o r s 5 2 2 5 )

28      1-11     A l l    MODE S H A P E S




                             -23-
      Card        Columns         Format        Description

      29            1-4           A4            TRAN      T r a n s v e r s e mode s h a p e s

                  38-40           I 3           20   Number of mode s h a p e s t o be
                                                output     0




                  43-45           I3            36      Number o f i n c r e m e n t s f o r s h e l l .
                                                [ D i s p l a c e m e n t s o u t p u t a t 5 degree
                                                intervals]

                   48-50          I 3           10     Number of i n c r e m e n t s f o r f l o o r
                                                [Displacements o u t p u t a t i n t e r v a l s of
                                                f l o o r w i d t h Lp/20].

                    55            L1            T     u and v d i s p l a c e m e n t s c a l c u l a t e d

                    60            L1            T     o u t p u t r e q u i r e d on Tape 7 .

       30           1 -3          A3            END


       31           1-10          A10           END OF JOB


       32           1              6 / 7 / 8 / 9 End of f i l e .



No l i b r a r y s u b r o u t i n e s a r e r e q u i r e d .
                                                  The program MRP must b e r u n
t w i c e , once f o r SYMMETRIC modes and o n c e f o r ANTISYMMETRIC modes.
The same d a t a i s u s e d i n b o t h cases e x c e p t f o r Card 5.
5.2.2       Output F i l e , Tape 7

The two o u t p u t f i l e s , Tape 7 , one f o r s y m m e t r i c a n d one f o r a n t i -
symmetric modes, must b o t h b e c a t a l o g e d o r s t o r e d f o r i n p u t t o
program MRPMOD.           T h e s e o u t p u t f i l e s may be l a r g e i f a x i a l mode
o r d e r s M = 1 t o 10 a r e a l l i n c l u d e d a n d care s h o u l d be t a k e n t o
a l l o w f o r t h i s . F o r example, on t h e CDC N O S c o m p u t i n g s e r v i c e ,
Tape 7 s h o u l d be d e f i n e d as a D i r e c t Access F i l e rather t h a n a n
I n d i r e c t Access F i l e which i s l i m i t e d i n s i z e .

F o r each v a l u e of M i n t u r n , t h e o u t p u t f i l e , Tape 7 , c o n t a i n s
i n f o r m a t i o n on t h e f i r s t 20 n o r m a l modes i n c l u d i n g

        Resonance f r e q u e n c i e s
        Generalized coordinates
        Shell displacements
        Floor displacements

5.2.3       P r i n t e d Output

S h e l l a n d P l a t e s t r u c t u r a l data.
F o r e a c h v a l u e of M i n t u r n :

        C o n s t r a i n t matrices
        E i g e n v a l u e s a n d Resonance f r e q u e n c i e s
        G e n e r a l i z e d c o o r d i n a t e s f o r f i r s t 20 modes
        S h e l l a n d f l o o r d i s p l a c e m e n t s f o r f i r s t 20 modes
        G r a p h i c a l r e p r e s e n t a t i o n of mode s h a p e s .




                                                 -25-
5.3 Program MRPMOD

5.3.1    Input Data

        -
        Card Columns   Format   Description
          1   1-80     16A5     T i t l e c a r d . This w i l l b e passed t o
                                program PAIN by Tape 9 o u t p u t .

          2   1-5      I5       No. o f terms u s e d f o r s h e l l
                                d i s p l a c e m e n t s e r i e s i n program
                                MRP [ F i n a l ns + 1 3


              6-10     I5       No. o f terms u s e d f o r f l o o r
                                d i s p l a c e m e n t s e r i e s i n program
                                MRP [ F i n a l np + 11


          3   1-5      I5       No. o f v a l u e s o f M i n program MRP.
                                Maximum no. o f l o n g i t u d i n a l h a l f -
                                wavelengths.

          4   1-5      I5       No. of terms u s e d f o r s h e l l d i s -
                                p l a c e m e n t s e r i e s i n program PAIN
                                [Maximum = 53

              6-10     I5       No. o f terms u s e d f o r f l o o r d i s p l a c e -
                                ment s e r i e s i n program PAIN
                                [Maximum = 3 1
                                [ F o r t h e s e , t h e most s i g n i f i c a n t
                                terms of t h e s e r i e s w i l l b e s e l e c t e d
                                b y program MRPMOD]


         5    1-10     F10.0    Angle eo (degrees) a t which t h e f l o o r
                                j o i n t i s l o c a t e d ( e o = 0 a t bottom
                                centerline)




                                 -26-
        -
        Card        Columns         Format          Description

            6       1-10          F1O.O        Cylinder length (m)
                   11-20          F1O.O        Cylinder radius (m)

            7        1-10         F1O.O         S h e l l m a s d u n i t area (kg/m2) i n c l u d -
                                                i n g ' s m e a r e d - o u t ' s t i f f e n e r masses
                   11-20          F1O.O         F l o o r m a s s / u n i t area (kg/m2) i n c l u d -
                                                i n g ' s m e a r e d - o u t ' s t i f f e n e r masses

            8        1-31 5X,Il,5A5             T A P E 7 S Y M M E T R I C MODES


            9          1-31 5X311,5A5           T A P E 8 A N T I S Y M M E T R I C MODES


           10          1       6/7/8/9          End o f F i l e .

5.3.2       Input F i l e s

Two f i l e s must be s p e c i f i e d

        Tape 7     -
                 Symmetric modes o u t p u t f r o m Program MRP
        Tape 8 - Antisymmetric modes o u t p u t f r o m Program MRP

5.3.3       Output F i l e , Tape 9

The o u t p u t f i l e , Tape 9 , m u s t b e c a t a l o g e d o r s t o r e d f o r i n p u t t o
program PAIN. Tape 9 c o n t a i n s i n f o r m a t i o n f o r a l l t h e modes,
s y m m e t r i c and a n t i s y m m e t r i c f o r a l l v a l u e s of M , a r r a n g e d i n
a s c e n d i n g o r d e r of f r e q u e n c y . The o u t p u t f o r e a c h mode i s

        Frequency
        Mode symmetry
        G e n e r a l i z e d mass
        Most s i g n i f i c a n t g e n e r a l i z e d c o o r d i n a t e s f o r s h e l l a n d f l o o r
        S h e l l displacements a t 5 degree i n t e r v a l s


                                                    -27-
5.3.4        Printed Output

A summary i s p r i n t e d f o r e a c h mode g i v i n g :

        Frequency
        Mode symmetry        .
        M = number of l o n g i t u d i n a l h a l f - w a v e l e n g t h s
   Gin = Most S i g n i f i c a n t s h e l l g e n e r a l i z e d c o o r d i n a t e s (Max 5 )
    ns = number of s h e l l c i r c u m f e r e n t i a l waves, a s s o c i a t e d w i t h
            each s h e l l g e n e r a l i z e d c o o r d i n a t e
   CMn - Most s i g n i f i c a n t f l o o r g e n e r a l i z e d c o o r d i n a t e s (Max 3 )
    n = number of h a l f - w a v e l e n g t h s i n f l o o r w i d t h a s s o c i a t e d w i t h
     P
            each f l o o r g e n e r a l i z e d c o o r d i n a t e
     T o t a l g e n e r a l i z e d mass f o r t h e mode ( k g )
     Component of g e n e r a l i z e d mass due t o s h e l l normal d i s p l a c e -
     ment (kg)
     Component of g e n e r a l i z e d mass due t o f l o o r normal d i s p l a c e -
     ment ( k g )

5.4         Program PAIN

5.4.1         Input Data

   Card         Columns          Format        Description

        1            1-80        16A5          T i t l e card

        2           1-10         F10.2         E x t e r i o r a i r d e n s i t y (kg/m3)
                   11-20         F10.2         I n t e r i o r a i r d e n s i t y (kg/m3)
                   21-30         F10.2         E x t e r i o r speed of sound ( m / s e c )
                   31-40         F10.2         I n t e r i o r s p e e d of sound ( m / s e c >

        3            1-5         I5            N I = Number o f 1 / 3 o c t a v e band c e n t e r
                                               f r e q u e n c i e s (maximum 26)




                                                  -28-
***The number o f i n p u t d a t a c a r d s w i l l v a r y d e p e n d i n g on t h e
   v a l u e of N I , s i n c e t h e input format f o r f r e q u e n c i e s , l o s s
   f a c t o r s , etc.      i s 8F10.2.  The card numbers t h a t f o l l o w a r e
   c o r r e c t o n l y f o r 16<N1<25***

     Card      Columns      Format        Description

     4,5,6        1-10       F10.2        Lowest 1 / 3 o c t a v e band c e n t e r
                                          frequency (Hz)
                 1 1 -20      F10.2       2nd 1 / 3 o c t a v e band f r e q u e n c y ( H z )
                                          [8 f r e q u e n c i e s p e r c a r d ]



                             F10.2        ( N 1 ) t h 1 / 3 o c t a v e band f r e q . ( H z )

        7         1-10        F10.2       L = Fuselage c y l i n d e r l e n g t h ( m )
                 11-20        F10.2       a = cylinder radius (m)
                 21 -30       F10.2       e, = a n g l e a t which f l o o r j o i n t i s
                                          l o c a t e d ( d e g r e e s ) e, = 0 i s t h e
                                          bottom c e n t e r l i n e
                 31 -40       F10.2       v = P o i s s o n ' s r a t i o ( f o r end c a p s )
                                          [ A t t h e moment, t r a n s m i s s i o n t h r o u g h
                                          t h e end c a p s h a s n o t b e e n i n c l u d e d
                                          i n t h e program, b u t t h i s may b e added
                                          later].

        8         1-80        16A5        Title card, describing t h e cavity

        9         1-1 0      F10.2        Lc = C a v i t y l e n g t h ( m )
                 1 1 -20     F10.2        d = distance of start of structure
                                          from s t a r t o f c a v i t y ( d + v e L < L c ;
                                          d - v e L>Lc)




                                         -29-
-
Card Columns         Format    DescriDtion

 10         1-1 0     F10.2    The c e n t e r f r e q u e n c y o f t h e f i r s t
                               l / 3 o c t a v e band i n which t h e high-
                               f r e q u e n c y f o r m u l a t i o n is used ( H z )
                               (See Section 3 (8))
                               If t h i s v a l u e i s z e r o , t h e program
                               estimates a frequency.
                               If t h i s v a l u e is non-zero, t h e i n p u t
                               v a l u e i s used, n o t t h e estimated
                               value.


  11        1-25      5A5      STRUCTURAL L O S S FACTORS


12,13914    1-10      F10.2    S t r u c t u r a l l o s s f a c t o r f o r lowest
                               f r e q u e n c y band.
           11-20      F10.2    S t r u c t u r a l l o s s f a c t o r f o r 2nd band.



                      F10.2    Structural l o s s f a c t o r f o r (N1)th
                               band.

  15        1-25      5A5      A C O U S T I C L O S S FACTORS
                               The a c o u s t i c l o s s f a c t o r s must b e
                               input f o r a bare fuselage.                If t h e
                               i n p u t l o s s f a c t o r s are z e r o , t h e n t h e
                               c a b i n t r i m d a t a i s used t o c a l c u l a t e
                               them.

16,17918    1-10      F10.2    Acoustic l o s s f a c t o r f o r lowest
                               f r e q u e n c y band ( z e r o i f c a l c u l a t e d
                               u s i n g trim d a t a ) .
           1 1 -20    F10.2    A c o u s t i c l o s s f a c t o r f o r 2nd band.



                      F10.2    A c o u s t i c l o s s f a c t o r f o r ( N 1 ) t h band.

                              - 30-
     Card        Columns       Format         Description

       19           1-80         16A5          Title card, describing t h e t r i m .

       20           1-10        F10.2          h t = i n s u l a t i o n t h i c k n e s s ( m ) on
                                               curved w a l l o f c y l i n d e r .
                  11-20         F10-2          m t = m a s s / u n i t area (kg/m2) o f
                                               the t r i m lining, facing the cavity.
                  21-30         F10.2          A t = S u r f a c e a r e a ( m 2 ) of t h e
                                               trim on t h e c u r v e d c y l i n d e r w a l l .

                  31-40          F10.2         nt   t r i m lining loss factor ( i n
                                                     =
                                               flexure)      .
***If t h e r e i s no t r i m , t h e v a l u e of h t = 0 must b e i n p u t and
    C a r d s 21-33, t h e remaining trim d a t a , should be o m i t t e d .
    With no t r i m , t h e a c o u s t i c l o s s f a c t o r s must b e i n p u t on c a r d s
    16-1 8."""


                                                         If h t # 0

       21           1-10         F10.2         he = i n s u l a t i o n t h i c k n e s s on e n d
                                               caps (d
                   11-20         F10.2         me = m a s s / u n i t area (kg/m2) o f
                                               t h e end c a p t r i m l i n i n g , f a c i n g t h e
                                               cavity.
                   21-30         F10.2         A, = s u r f a c e a r e a (m2) o f t h e
                                               t r i m on one end c a p .
                   31-40         F10.2               = end c a p trim l i n i n g l o s s f a c t o r
                                               'I,
                                               (in flexure)

***For e a c h f r e q u e n c y band, t h e t r i m i n s u l a t i o n c h a r a c t e r i s t i c s
   are i n p u t . ( F o r F i b e r g l a s Type PF105, t h e v a l u e s a r e g i v e n i n
   Ref.[3], Page 4 8 2 ) * * *
  Card     Columns    Format    Description

22,23,24     1-10      F10.2    ct    = a t t e n u a t i o n c o n s t a n t (dB/m)   for
                                f i r s t f r e q u e n c y band.

            1 1 -20    F10.2    ct    f o r 2nd f r e q u e n c y b a n d .




                       F10.2    ct    f o r ( N i ) t h e f r e q u e n c y band.

25,26,27     1-10      F10.2    A,     =a c o u s t i c wavelength i n m a t e r i a l
                                ( m ) f o r f i r s t f r e q u e n c y band.

            1 1 -20    F10.2    A,     f o r 2nd f r e q u e n c y band.




                       F10.2    A,     f o r ( N 1 ) t h f r e q u e n c y band.

28,29,70     1-10      F10.2    IwI       a m p l i t u d e o f wave impedance
                                           =
                                (mks r a y l s ) o f trim i n s u l a t i o n f o r
                                f i r s t f r e q u e n c y band

            1 1 -20    F10.2    I Wi       f o r 2nd f r e q u e n c y band.




                       F10.2    1 Wl       f o r ( N 1 ) t h f r e q u e n c y band.




                               -32-
  Card     Columns   Format   Description

31,32,33     1-10     F10.2   I$ = p h a s e of wave impedance ( d e g r e e s )
                              f o r f i r s t f r e q u e n c y band [ + v e v a l u e s ]

            11-20     F10.2   I$ f o r    2nd f r e q u e n c y band.



                     F10.2    I$    f o r ( N 1 ) t h f r e q u e n c y band.

   34        1-15     3A5          P R O P E L L E R TONES




   35        1-80     16A5    T i t l e card, describing the propeller
                              data.        Propeller location is
                              ( r p , @ , z p ) [ S e e F i g u r e 21

   36        1-10    F10.2    rp = d i s t a n c e of p r o p e l l e r c e n t e r -
                              l i n e from f u s e l a g e c e n t e r l i n e ( m >

            11-20    F10.2    @      = angle      between v e r t i c a l and t h e
                              l i n e from p r o p e l l e r t o f u s e l a g e
                              c e n t e r l i n e ( d e g r e e s ) [ $ must be g i v e n
                              t o the nearest 5 degrees]
           21-30     F10.2    z p = d i s t a n c e of p r o p e l l e r p l a n e
                              from f o r w a r d end of f u s e l a g e (m>

           31-40     F10.2    B = No. of b l a d e s of p r o p e l l e r .
           41-50     F10.2    P r o p e l l e r rpm, f o r which p r o p e l l e r
                              sound p r e s s u r e s were p r e d i c t e d .




                              -33-
      Card       Columns       Format          Description



        36        5 1-60         F10.2         +l. 0      If p r o p e l l e r r o t a t e s c o u n t e r -
                                               clockwise i n z d i r e c t i o n (as i n
                                               F i g u r e 3 ) ; o r -1.0  i f propeller
                                               r o t a t e s clockwise i n z d i r e c t i o n .

                                               ( I n p u t d a t a c r e a t e d u s i n g ANOPP must
                                               b e b l a d e downsweep o n l y )


***The p r o p e l l e r p r e s s u r e s i g n a t u r e i s d e f i n e d a t g r i d p o i n t s o n
   t h e u p p e r q u a r t e r of t h e f u s e l a g e s k i n , a n d i n p u t , u s i n g a
   F o u r i e r s e r i e s a n a l y s i s , as t h e a m p l i t u d e a n d p h a s e a t t h e
   p r o p e l l e r h a r m o n i c s f o r e a c h g r i d p o i n t . The o u t p u t f r o m a
   p r o p e l l e r n o i s e p r e d i c t i o n program [l] has been u s e d as p a r t of
   t h i s d a t a i n p u t package.             The l o c a t i o n of t h e g r i d p o i n t s i s
   d e f i n e d i n F i g u r e 3.***

       37           1-5          I5            H m a x = No. o f p r o p e l l e r h a r m o n i c s
                                               (Maximum = 1 0 ) .

                    6-1 0        I5            k        = Number o f a x i a l g r i d c o o r d i -
                                                max
                                               n a t e s (Maximum = 1 6 ) .

                   11-15         I5            kp = A x i a l g r i d c o o r d i n a t e a t
                                               which p r o p e l l e r p l a n e i s l o c a t e d .


The f o l l o w i n g (Hmax     x kma, x10) c a r d s c o n t a i n t h e p r e s s u r e
a m p l i t u d e and p h a s e f o r e v e r y g r i d p o i n t ( k , R ) f o r all t h e
p r o p e l l e r harmonics H.

      38            1-4          I4            k = Grid a x i a l coordinate
   onwards          5-8          I4            R = Grid circumferential coordinate




                                               -34-
       Card        Columns        Format           Description

        38             9-14         F6.2                         ANOPP c o o r d i n a t e s
     onwards         15-20          F6.2                         defined i n Figure 3
     (contd)         21-26          F6.2                         ( n o t u s e d by Program P A I N )

                    27-32           I6              H = h a r m o n i c number.
                     33-48          E16.5           + , ( k , a ) = p h a s e o f F o u r i e r component
                                                    f o r h a r m o n i c H a t l o c a t i o n ( k , R ) (degrees)
                     49-64          E16.5           Aik")       = a m p l i t u d e o f F o u r i e r compon-
                                                    e n t f o r Harmonic H a t l o c a t i o n ( k , i ) (Pa)

T h i s f o r m a t i s r e p e a t e d u n t i l a l l v a l u e s o f k , R and H h a v e b e e n
used.

                        1        6/7/8/9            End o f f i l e .

No l i b r a r y s u b r o u t i n e s a r e r e q u i r e d .

5.4.2        Input F i l e 8

Two f i l e s must b e s p e c i f i e d .

       Tape 9 - S t r u c t u r a l modes o u t p u t from program MRPMOD.
      Tape 1 1     -
                A c o u s t i c modes o u t p u t from program CYL2D.

5.4.3        Printed Output

1.     Band-averaged l o s s f a c t o r s

       A c o u s t i c l o s s f a c t o r K n , e i t h e r i n p u t o r c a l c u l a t e d v a l u e s when
          t r i m is present
                                                    struc
       S t r u c t u r a l l o s s f a c t o r s n,        input
                                                               rad
       External radiation loss factors 1                    ',
       T o t a l s t r u c t u r a l l o s s f a c t o r 6; when t r i m is p r e s e n t .



                                                     -35-
T r i m Data

T r i m characteristics input
T r i m t r a n s m i s s i o n c o e f f i c i e n t (dB) 10 l o g ( l / ~ ~ )
T r i m and end c a p a d m i t t a n c e s , r e a l and i m a g i n a r y .
    (non-d i m e n s i o n a l )

Number o f s t r u c t u r a l and a c o u s t i c modes i n each 1/3 o c t a v e
frequency band.

S t r u c t u r a l Modes.     F o r e a c h mode:

F r e que n c y
Symmetry
Total structural loss f a c t o r n i
M = number o f l o n g i t u d i n a l h a l f - w a v e l e n g t h s
F o r t h e most s i g n i f i c a n t d i s p l a c e m e n t s e r i e s terms f o r
   s h e l l and f l o o r : -
     ns = number o f c i r c u m f e r e n t i a l w a v e l e n g t h s f o r s h e l l
   Cin = g e n e r a l i z e d c o o r d i n a t e f o r s h e l l
    np = number of t r a n s v e r s e h a l f - w a v e l e n g t h s   for floor
    P
   CMn = g e n e r a l i z e d c o o r d i n a t e f o r f l o o r
   T o t a l g e n e r a l i z e d mass ( k g )
   Gen. mass a s s o c i a t e d w i t h s h e l l normal d i s p l a c e m e n t (kg)
   Gen. mass a s s o c i a t e d w i t h f l o o r normal d i s p l a c e m e n t ( k g )
   R e v e r b e r a n t f i e l d j o i n t a c c e p t a n c e j 2(rev)

A c o u s t i c modes.       For e a c h mode:

Frequency
Symmetry
q = no. o f l o n g i t u d i n a l h a l f - w a v e l e n g t h s
i = mode c o u n t e r f o r c y l i n d e r c r o s s - s e c t i o n modes.
Acoustic l o s s f a c t o r
                                    n
                                     .
No rmali z a t i o n p a r a m e t e r En.
6.   Acoustic/structural coupling f a c t o r s .

     F o r a c o u s t i c mode n = ( q , i ) and s t r u c t u r a l mode r = ( M , N )            let




     V a l u e s of f i N a r e o u t p u t f o r b o t h s h e l l and f l o o r .

7.   P r o p e l l e r P r e s s u r e Amplitude a n d Phase

     O u t p u t f o r a l l g r i d p o i n t s , b o t h above and below 0 = 0, f o r
     e a c h p r o p e l l e r harmonic,
     P r e s s u r e a m p l i t u d e (dB re 20 m i c r o p a ) i n c l u d i n g r e f l e c t i n g
     surface effects.
     P r e s s u r e Phase ( d e g r e e s )

8.   Propeller generalized forces.

     F o r e a c h harmonic H a n d s t r u c t u r a l mode r ,
     G e n e r a l i z e d f o r c e YG(r,H)     -
                                              (see Ref.[2], Equation 4 2 ) .

9.   Tone T r a n s m i s s i o n f o r P r o p e l l e r Harmonics       -
     I n t e r i o r s p a c e - a v e r a g e d mean s q u a r e p r e s s u r e (dB r e 20 m i c r o p a )

     1) Low f r e q u e n c y f o r m u l a t i o n c a l c u l a t i o n s o n l y , f o r a l l harmon-
          i c s , i d e n t i f y i n g 5 modes making t h e l a r g e s t c o n t r i b u t i o n s .
          n; ' o u t p u t t o i d e n t i f y c l o s e l y c o u p l e d s t r u c t u r a l a n d
          a c o u s t i c modes.

     2 ) Summary o f low f r e q u e n c y f o r m u l a t i o n ( w h e r e s p e c i f i e d ) and
          t h e high frequency formulation (expected v a l u e ) f o r a l l
          harmonics.

     3 ) Summary o f p r e d i c t e d i n t e r i o r s p a c e - a v e r a g e d mean s q u a r e
          p r e s s u r e ( d B r e 20 m i c r o p a ) .


                                                -37-
6.0    CONTROL CARDS FOR EXECUTING THE PROGRAM

The c o n t r o l c a r d s t h a t f o l l o w a r e f o r t h e CDC CYBERNET NOS
Computing S e r v i c e . A l l t h e p r o g r a m s , CYL2D, MRP, MRPMOD a n d
PAIN, a r e w r i t t e n i n F o r t r a n E x t e n d e d 4 , and comply w i t h ANSI
1966 F o r t r a n f o r t h e most p a r t , e x c e p t where s p e c i f i c CDC
f u n c t i o n s s u c h as EOF were r e q u i r e d .     I n addition, it is
assumed t h a t IMSL l i b r a r y s u b r o u t i n e s a r e a v a i l a b l e f o r
program CYL2DF.

The c o n t r o l c a r d s assume t h a t t h e F o r t r a n programs are s t o r e d
as permanent f i l e s on d i s c s t o r a g e w i t h t h e names CYL2DF,
MRPF, MRPMODF and PAIN.         I n p u t and o u t p u t d a t a are a l s o s t o r e d
a s permanent f i l e s . Sample i n p u t d a t a f o r e a c h program a r e
a l s o given.
6.1        Control Cards and Data f o r Program CYL2D


/JOE
   r
PA 14. T i    .~4 .
             x)
/USER
/CHARGE
ROUTE. OUTPUT. DC=PR. UN=*******.      ST=**+,   DEF.
       .
GE7 CYL2DF.
F I N . R=3.
                                            Fortran Fâ€ropam CYL2DF
REWTND.1 G O .
RFPLAt:E.LGn=CYl 2DC.
GOIO. 1 .
EXIT.
I . S7 I M E -
Dfiâ€™fF I I E .
/EDF
/REGD. C Y L Z D F
/EOF




/,70F
P A I N. 7 400. P4   I




/llSEF(
/CHARGE
HOUTE.OUTPUT.DC=PR.UN=+*****+t*.ST=***.DEF.
GET.CYL2DD.                                 Input Data File CYL2DD
A 7 TACH. IMSi /I.IN=I_IBRARY.              Library Subroutines
BL IBRARY. IMSL..
       .         -
GE r c y i - ~ D C :                        (hrrij) i 1 1â€™x~o~:rxm Dâ€™I,?IXâ€™
C n F â€™ Y B F . CYL2DC. L E O .
I D S E l (PRESâ‚¬l=ZERO)
1 ELI. PL = 5 t )(:)(-)( ) -
R E P t 6 C E . T A P E 1 1=CYLS6.
GOTO. 1.
EXIT.
1. S T I M E .
DAYFJL E .
/FnR
I R F R D . C Y L 31m
/ E DF


            CYL2DD            Input Data File
   56.6




                                        -39 -
6.2    Control Cards and Data f o r Program MRP




G E T . MRPF.
F T N . R=3.
REWIND.LG0.
REPL ACE. LGO=MRPC.                                Cornpiled Prorjarn MRrC
GOTO. 1.
EXIT.
1.STIMF.
DAYF I LE.
/EOR
/READ. MRPF
/EOF

Control Cards for Symmetric Modes

/JOB
PAIN. T400.Pl       I




/USER
/CHARGE
ROUTâ‚¬. OLITPIJT. DC=PR. LJN=*******.        ST=+++. D E F .
DEFINE.TAPE7=MRPSM.           I j i rcct Acccss Output Pile    W   S   b   I


GET. MRPSD.                   T ~ I ~ J U 'Data
                                           L    F i l e PWSD
G E T , MRPC    .             Corq)i led froflrrrl MW'C
CDPYBF.MRPC.1 GD.
L D S E T (PRESE T = ZERO
L m. PI =5t )(-)( )( ).
GTJTO. 1-
EXIT.
1. S T IME  .
DAYF I L E .
/EOR
/READ. MRPSD
/EOF




                                        - 40-
                                            ~
Control Card8 for Antisymmetric Nodes

 /JOB
PGIN. T 4 0 0 . P1.
/USER
/CHfiRGE
ROlJTE. OLlTPlJT. DC=PR. IJN=**+*+**,   ST=***.   DEF.
D E F I N E . TGPE7=MRPCSM.             D i r e c t Access Output. F i l e MRPM1
GET. MRPCSD.                            Input Data File MRPRI)
GE T I MRPC  .
COPYEF. MRPC. LGO).                     Compiled Promam MRPC
LDSET (PRESET=ZERO)
LGO, PL =5CWO(>.
GOTO. 1  -
EXIT.
 1 STIME.
DfiYFILE.
/EOR
/READ. MRPAD
/EOF




                                         -41-
              ~ P S DInput              Data File ror Symmetric Modes
  S T I F F E N E D .032 I N C Y L I N D E R . 20 I N R A D I U S . WITH FLOOR 4 T 56.6 DEGREES.
  MCIDEI # 5 C Y L I N D E R .  PHf4SE 1 1 1 .
      FREE1.Y SIJPPDRlEI) E N D C O N D I T I O N S . R I G I D , I O I N - I A I F L O O R - C Y L I N D E R JUIdCT I O N
      S Y M M E T R I C MODES.  OUTPUT ON MRPSM F W M = l - l O MODES
END
I N P U T DATA
GENERAL
           F R E E L Y SUPPORTED                      RIGID                                                  SYMMETKIC
                                56.6
               1           10       1     0               12   1    (1)   E
                                                                          ..I             1
               T            T       F
SHE1 1.
               7.239495E 1 0                  -
                                          7 239495E 1i-)                          -   -7
                                                                                      L b . 2


               0 . 00 1 1'53058              3. 1139:3.3                        0.5U8
                       62.352938                  .
                                              1 2i)0725E4
PL-ATE
               7 239495E 1 0
                   I                      7 239495E 1 0
                                              I                                   I
                                                                                      --
                                                                                      .>.I>           .-.>-\
                                                                                                          --

                       .
                0 00 1 2 7 6 2 2            3 446537 2I




               8.629765'9E3               5.4X4ZS4EZ
END
GENERATE M A T R T C F S
CONSTRA IN l
SHE 1-1.
PLATE
END
SOLVE
PUNCH
FREOUENCIES
EIIXNVECTORS
           15
MODE S H A P E S
THAN
END
END OF JOB




                                                                   -42-
             HRPAD         Input Data F i l e f o r Antisymmetric Modes
 S T I F F E N E D .032 I N C Y L I N D E R . 20 I N R A D I U S . W I T H FLOOR A T 56.6 DEGREES.
 MODEL #5 C Y L I N D E R .       PHASE 111.
    F R E E L Y SUPPORTED END C O N D I T I O N S . R I G I D J O I N T AT FLOOR-CYLINDER JIII\ICTIDl\i
    A N T I S Y M M E T R I C MODES.    OUTPUT ON MRPAM FOR M = l - l 0 MODES
ENI)
1NPll7 D A I A
EENI-
         FREEL Y SUPPOf37-ED                                  RIGID                                                         AN7- I S Y M M t 1 k I (-1
                           56.6
                                                                        CT
             1       1 0         1    0           12     1        (1)   LJ                    1
             T         T         F
SHELL.
             7 . 2 3 9 4 9 5 E 1 C)   7 2 3 9 4 9 5 E 1 C)
                                          I                                      .-- L%       ->                . .--.
                                                                                                                    7-
                                                                                                                    .-I


             (1). CJC:J 1 1 53058         3 . 1 1 393:                       I   3:)8                   1 8034
                                                                                                            .
                                                                                                            )




                  62.35'2938                  .
                                       1 20(')?25E4
FLATE
                 -
             7 239495F 1 (-)          7 2 3 9 4 9 5 E 1 I:)
                                          I                                      I
                                                                                     --
                                                                                     .-\.:,                     I
                                                                                                                    7 7
                                                                                                                    .>.in

              0 . 0 0 1 27622           3.4465372
             8.6297699E3              5.4264354E3
END
GENERATE M A T R I C E S
CONSTRAINT
SHâ‚¬L I
PI A T â‚¬
E ND
Snl VE
PUNCH
FREDIJENC: I E 5
EIGENVECTORS
           15
MODE SHAPES
TF(AI\I                                                          15     36            10           1'   T
END
F N D OF JOF!




                                                                -43-
6.3        Control Cards and Data for Program MRPMOD

/JOE
P A 1N. T 1 5 0 , P 4 .
/LEER
/CHARGE
ROUTE. OUTPUT, DC=PR. UN=*******,     ST=*+*, DEF.
GET. MRPMODF.                Fortran Program MRPMODF
FTN.R='T.
RFWIND,LGO.
REPk ACE.LGO=MRPMODC.        Corrq)i 1td Progrrvri MFW10DC
GOTO, 1.
EXIT.
1.STIME.
D A Y F I LE.
/EOR
/'HFAD. MRPMODF
/EOF


/JDB
          .    . .
P A I N T 4 W) P 3
/ I JSER
/CHARGE
ROUTE. O U T W T . DC=PR. UN=*******, ST=*+*,                           DEF.
G E T , MRPMODD.                   I n p u t d a t a f i l e MRT'IbIODD
A T T A C H . lAPE7=MRPSM.         :;yrnmetYic Modes F i l e M R P m
FITTACH. TAPF8=MRPAM,              A n L i :;yrrirrict,r~i c M o t l ~ s Vi J e MRT'Ar4
      .
GET MRF'MCIDT'        .            ( ; c J r [ l l i i 1 (?ti l ' l A ( ~ f r I ' X KMIII'MODC
                                                                                     \
COPYBF. MRPMDDC. LLGO.
L I X E T (PRâ‚¬SFT=ZERO)
LGO. PL=SOQ(~)t-)
REPL FSCE. T O P E 9 = S T R 5 6 .  Output File STR5.6
GOTO. 1.
EXIT,
1.STIME.
D A Y F II F .
/ECW
/READ. MRPMC)DI)
/â‚¬OF

        ~RPMODD           Input Data File

  SlIFFENED .052 IN CYLINDER. W I T H STIFFENED FLOOR AT 56.6 DEGREES
      17        6
      1 f-)

56.6
          c
          LJ    7
                ._I                                                                              .
  .
1 8034            0.Sib8
3 - 1 1324 3.44578
TAPE 7 SYHHETRIC M D E S
TAPE 8 fiNTJSYMMETRIC MODES




                                                     - 44-
/JOB
PCIIN. 1 1 5 0 . P4.
/USER
ICH6RGE
ROUTE.OUTPUT.DC=PR.UN=*******.ST=***.DEF-
GE7 . P A I N .                Pr ~rt,
                                    r w i Prlc)/ ~ymiPATIJ
FlN. R=3.
R E W I N D . L.GO.
REPLfXE.LGO=PAINC.                          Compiled Program PAIIJC
GOTO. 1 .
EXIT.
1, S T I M E   .
DAYF ILE.
/EOR
/HL-AD. P A I N
/EOF




/JOE
P A I N . T 4 0 0 . P3. C M 3 7 8 0 0 0 ,
/USER
/CHARGE
ROIITE.OUTPU7 .DC=PR.IJN=+++++++,ST=+*+.DEF.
GET.PAIND.                     I r q ~ u tl);it:r lciJ(: I'AIJJI)
GET,TAPE9=STR56.              S t r u c t u r a l Modes File S",TR50
GET,Tf+PEll=CYLS6,            Acoustic Modes File CYL56
GET.PA1NC.                    Compiled P r o p a m PAINC
COPYBF.PCIINC.LG0.
LDSET (PRESET=ZERO)
LGO ,PL =500(:)0.
GOTO. 1    I



EXIT.
1 .STIME.
DAYFILE.
/EOR
/READ.PAIND
/EOF




                                                - 45-
 6.4   Control Cards and Data for Program PAIN
/JOB
P A I N . T15O.P4.
/USER
/CHARGE
ROUTE.OUTPUT.DC=PR.UN=*******.ST=***.DEF~
GET,PAIN.                      Fortran P ~ O ~ J WPAIN
                                                   T
FTN. R=3.
REWIND.LG0.
REPLACE. L G O = P A I NC.     Compiled Program PAINC
GOTO. 1.
EXIT.
1. S T I M E .
DAYFILE.
/EOR
/READ. P A I N
/EOF




/JOB
PAIN. T400.P3.CM370000.
/USER
/CHARGE
RclUTE, OUTPUT. DC=PR. UN=+++*+++. S T = + + + , DEF.
GET.PAIND.                     Input Data File PAIND
GET.TAPES=STR5.5.              Structural Modes File STR56
GET.TAPEll=CYL!%.              Acoustic Modes File CYL56
GET.PAINC.                     Compiled Program PAINC
COPYBF. P A I N C . LGO.
LDSET(PRESET=ZERO)
LGO. PL=50000.
GOTO. 1.
EXIT.
1 .STIME.
DAYF ILE.
/EOR
/READ, PCI I ND
/EOF




                                    - 45-
                                   REFERENCES


1.   P a d u l a , S.L., and B l o c k , P.J.W.,       llAcoustic P r e d i c t i o n
     Methods f o r t h e N A S A G e n e r a l i z e d Advanced P r o p e l l e r
     A n a l y s i s System,'' A I A A P a p e r 84-2243, J u l y 1984.

2.   Pope, L.D., W i l b y , E.G., and W i l b y , J . F . , " P r o p e l l e r
     A i r c r a f t I n t e r i o r Noise Model," N A S A CR 3813, 1984.

3.   Beranek, L.L., "Noise and V i b r a t i o n C o n t r o l , " McGraw-Hill
     Book Company, 1971.




                                            -47-
                                          APPENDIX A

                                        LIST OF SYMBOLS

A,     (m2>           S u r f a c e area of t r i m on one end cap.


AH ( k â€™ â€œ ( P a )    Amplitude of F o u r i e r component of p r o p e l l e r
                      p r e s s u r e s i g n a t u r e a t p r o p e l l e r h a r m o n i c H and
                      g r i d location (k,E)


AR ( m 2 )             C r o s s - s e c t i o n a l area of r i n g frames on t h e s h e l l
                       (or transverse f l o o r supports)

A~      (m2>           C r o s s - s e c t i o n a l area of s t r i n g e r s on t h e s h e l l ( o r
                       l o n g i t u d i n a l f l o o r beams)


At      (m2>           S u r f a c e area of t r i m on t h e c u r v e d c y l i n d e r wall.

a (m)                  Cylinder radius

     k â€™ R / 2 ( P a ) Mean p r o p e l l e r p r e s s u r e a m p l i t u d e a t g r i d l o c a t i o n
                       (k,2 )


B                      Number of p r o p e l l e r b l a d e s

 BPF = NB/60 (Hz) B l a d e p a s s a g e f r e q u e n c y

                       F l o o r and s h e l l g e n e r a l i z e d c o o r d i n a t e s f o r
 CDlnâ€™ CSr
        Mn
                       s t r u c t u r e mode r = ( M , N )

 C 01     ( m / s e c ) I n t e r i o r speed o f sound

 d (m)                 S p a c i n g between s t r i n g e r s ( o r f l o o r beams)

 d (m)                 D i s t a n c e of s t a r t o f s t r u c t u r e f r o m s t a r t of
                       c a v i t y [ d + v e L < L,; d           -  v e L > Lc]




                                                      A- 1
                                       LIST OF SYMBOLS
                                         (Continued)

E (N/m2)         S t i f f e n e r modulus of e l a s t i c i t y

E,      (N/m2)   S h e l l o r f l o o r modulus of e l a s t i c i t y i n a x i a l
                 d 1re c t Ion


Ey ( N / m 2 )   F l o o r modulus of e l a s t i c i t y i n t h e t r a n s v e r s e
                 d i rec t i o n


E8 ( N / m 2 )   S h e l l modulus o f e l a s t i c i t y i n c i r c u m f e r e n t i a l
                 d i r e ct i o n


f ' ( n , r ) = fqrlfiN Acoustic/structural             coupling f a c t o r f o r
                 a c o u s t i c mode n = ( q , l ) a n d s t r u c t u r a l mode r =
                 (M.N) [ s e e Ref.[2] Section 3.53

G x e (Il/m2 )   S h e l l o r f l o o r shear modulus


H                P r o p e l l e r harmonlc o r d e r


Hmax             Maximum number o f p r o p e l l e r h a r m o n i c s c o n s i d e r e d

h
    e    (m)     I n s u l a t i o n t h i c k n e s s on end c a p s

ht       (m)     I n s u l a t i o n t h l c k n e s s on c u r v e d wall of c y l i n d e r

I (m4>           Moment of i n e r t i a of s t i f f e n e r a b o u t s h e l l o r
                 f l o o r middle surface

1                A c o u s t i c mode number c o u n t e r f o r c y l i n d e r c r o s s -
                 s e c t i o n modes, a s s o c i a t e d w i t h mode n E ( q , l )

j       (rev)    R e v e r b e r a n t f i e l d j o i n t a c c e p t a n c e f o r each
                 s t r u c t u r a l mode
                                        LIST OF SYMBOLS
                                          (Continued)

k               A x i a l grid coordinate (non-dimensional) f o r p o i n t
                (k,R)

                A x i a l g r i d c o o r d i n a t e a t which p r o p e l l e r p l a n e i s
kP
                located

                Maximum number of a x i a l ' g r i d c o o r d i n a t e s
krnax

k = 2T/X        A c o u s t i c wave number

L       (m)     C y l i n d e r l e n g t h ( n o t i n c l u d i n g end caps)


Lc      (m)     Cylinder cavity length


LP      (rn)    F l o o r w i d t h (wall t o w a l l )

R               Circumferential grid c o o r d i n a t e (non-dimensional)
                f o r p o i n t (k, a )

M               Number o f l o n g i t u d i n a l h a l f - w a v e l e n g t h s f o r
                s t r u c t u r a l mode

m = p t (kg/m2)       Average s u r f a c e mass of t h e s h e l l o r f l o o r

me (kg/m )      M a s s / u n i t a r e a of end cap t r i m l i n i n g , f a c i n g t h e
                cavity

rnt   (kg/m )   M a s s / u n i t a r e a o f c y l i n d e r wall t r i m l i n i n g ,
                f a c i n g the cavity

N               P r o p e l l e r rpm

N               S t r u c t u r a l mode number c o u n t e r o n l y , a s s o c i a t e d
                w i t h mode r E ( M , N )
                                          LIST OF SYMBOLS
                                            (Continued)

    NI            Number of o n e - t h i r d o c t a v e band c e n t e r f r e q u e n c i e s
                  (Max 26)

    n              A c o u s t i c mode number n          5   (q,i)


    n ,"           Number of s h e l l c i r c u m f e r e n t i a l waves

    n              Number of h a l f - w a v e l e n g t h z      in floor w i d t h
        P

    n*             Number of terms i n d i s p l a c e m e n t s e r i e s f o r s h e l l
                   or floor

    p[(k,ll),t]   ( P a ) P r o p e l l e r pressure a t t i m e t a t g r i d l o c a t i o n
                          (k, a )


    9              Number o f l o n g i t u d i n a l h a l f - w a v e l e n g t h s f o r
                   a c o u s t i c mode, a s s o c i a t e d w i t h mode n 5 ( q , i )

                   Propeller radius

                   S t r u c t u r a l mode number r          5   (M,N)

                   R a d i a l d i s t a n c e f r o m c e n t e r of f u s e l a g e c y l i n d e r
                   t o t h e a x i s of r o t a t i o n of t h e p r o p e l l e r

    T1 = BPF-'(secs)       Period of p r o p e l l e r n o i s e s i g n a t u r e

    t (secs)       Time c o o r d i n a t e , over p r o p e l l e r n o i s e p e r i o d t = O
                   t o Ti
                                                                                                        .
                   E q u i v a l e n t t h i c k n e s s of s h e l l o r f l o o r ( s e e page
                   10 1


                   A c t u a l t h i c k n e s s of s h e l l o r f l o o r



\
                                                 A- 4
                                          LIST OF SYMBOLS
                                              (Continued)

u,v,w              S h e l l and f l o o r degrees of f r e e d o m


v (m3>             C a v i t y volume, above t h e f l o o r

I W I (mks r a y l s ) Amplitude of wave impedance of t r i m i n s u l a t i o n

X,Y,Z              Co-ordinate         s y s t e m (see F i g u r e 3 )

x x x              L o c a l c o o r d i n a t e s y s t e m u s e d f o r ANOPP p r o p e l l e r
 1 2 3
                   n o i s e p r e d i c t i o n (see F i g u r e 3 )

zP (m>             L o c a t i o n of p r o p e l l e r r e l a t i v e t o t h e f r o n t of t h e
                   c y l i n d e r (of l e n g t h L)

 a(dB/m)           Trim i n s u l a t i o n a t t e n u a t i o n c o n s t a n t

         ' a (m)   Grid spacing f o r propeller noise predictions
         iT
                   A c o u s t i c mode n n o r m a l i z a t i o n p a r a m e t e r (see
                   Ref.[2].

                   End c a p t r i m l i n i n g l o s s f a c t o r (In f l e x u r e )

                   A c o u s t i c loss f a c t o r f o r mode n

                   Average o n e - t h i r d o c t a v e band a c o u s t i c loss
                   factor

                   C y l i n d e r t r i m l i n i n g loss f a c t o r ( i n f l e x u r e )

 '''ts             Average o n e - t h i r d o c t a v e band s t r u c t u r a l loss
   r
   '
                   factor

   ,.,rad          Average o n e - t h i r d o c t a v e band e x t e r n a l r a d i a t i o n
    r
                   loss f a c t o r

                                                  A-5
                                          LIST OF SYMBOLS
                                            (Continued)


 'I;              T o t a l s t r u c t u r a l l o s s f a c t o r , i n c l u d i n g e f f e c t of
                   trim

                   Average o n e - t h i r d o c t a v e band t o t a l s t r u c t u r a l
                   loss fact'or, including t r i m


 Q;'               I n t e r n a l r a d i a t i o n l o s s f a c t o r , due t o c l o s e l y
                   c o u p l e d s t r u c t u r a l and a c x s t i c modes (see Page
                   43, R e f . C 2 ] ) .

B ( d e g r e e s ) S h e l l a n g u l a r c o o r d i n a t e (see F i g u r e 3 ) .     8 = 0 is
                    a t f u s e l a g e bottom c e n t e r l i n e

e,(degrees)           Angle a t which s h e l l / f l o o r j o i n t i s l o c a t e d

Xm(m)             Acoustic wavelength i n t r i m i n s u l a t i o n

v v v             P o i s s o n ' s r a t i o f o r s h e l l or f l o o r
     X e Y

V                 P o i s s o n ' s r a t i o f o r end c a p s

p(kg/m3           D e n s i t y of s h e l l o r f l o o r m a t e r i a l

'I
 t                Trim t r a n s m i s s i o n c o e f f i c i e n t = -10 l o g         ( T ~ )dB


4 ( d e g r e e s ) A n g u l a r p o s i t i o n of p r o p e l l e r hub r e l a t i v e t o
                    f u s e l a g e bottom c e n t e r l i n e (see F i g u r e 2 )

6 ( d e g r e e s ) P h a s e of wave impedance of t r i m I n s u l a t i o n

         ( d e g r e e s ) Phase o f F o u r i e r component of p r o p e l l e r
                           p r e s s u r e s i g n a t u r e a t p r o p e l l e r harmonic H and
                           grid l o c a t i o n (k,R)

     r
$s(zye)           S h e l l displacement a t l o c a t i o n           (2,   8) i n mode r


                                                A-6
                                             LIST OF SYMBOLS
                                               (Continued)

9; ( 2 4 )             F l o o r d i s p l a c e m e n t a t l o c a t i o n ( z , x ) I n mode r

YG ( r , H )           G e n e r a l i z e d modal f o r c i n g f u n c t i o n due t o
                       p r o p e l l e r n o i s e , mode r a t p r o p e l l e r harmonic H

w        (radians/sec) Angular frequency


w
    JI
          ( r a d l a n s / s e c ) Angular f r e q u e n c y o f p r o p e l l e r harmonic H




                                                     A- 7
                                                                                    BIBLIOGRAPHIC D A T A SHEET

I . Report No.                              2. Government Accession NO.                     3. Recipient's Catalog No.
       NASA CR-172425
4. Title and Subtitle                                                                       5 . Report Date
                                                                                                  Januarv 1985
    PROPELLER AIRCRAFT INTERIOR NOISE MODEL -                                               6. Performing organization Code
     USERS' MANUAL FOR COMPUTER PROGRAM

7. Author(s)                                                                                8. Performing Organization Report No
                     E.    G. WILBY,         L. D. POPE                                           5058
             _.
3. Performing Organization Name and Address                                                 10. Work Unit No.

    BOLT BERANEK AND NEWMAN I N C .                                                         11. Contract or Grant No.
    2 1 1 2 0 Vanowen S t r e e t                                                                        -
                                                                                                 NAS 1 1578 2
    Canoga P a r k , CA 9 1 3 0 3
                                                                                            13. Type of Repon and Period Covered
12. Sponsorino Agency Name and Address                                                            Contractor
    N a t i o n a l A e r o n a u t i c s & Space A d m i n i s t r a t i o n                     F i n a l Report
    W a s h i n g t o n , TIC: 20546

                                                                                        1   14. Sponsorin A ency Code
                                                                                                  505-3%?3
15. Supplementary Notes

    T e c h n i c a l R e p r e s e n t a t i v e of C o n t r a c t i n g O f f i c e r :
    W i l l i a m H. Mayes, Langley Research C e n t e r


16. Abstract
    A c o m p u t e r program e n t i t l e d        PAIN ( P r o p e l l e r A i r c r a f t I n t e r i o r Noise)
    h a s b e e n d e v e l o p e d t o p e r m i t c a l c u l a t i o n of t h e s o u n d - l e v e l s      in
                                                                                                               the cabin
    of a p r o p e l l e r - d r i v e n a i r p l a n e .   The f u s e l a g e i s m o d e l e d a s a c y l i n d e r
    w i t h a s t r u c t u r a l l y i n t e g r a l f l o o r , t h e c a b i n sidewall a n d f l o o r b e i n g
    s t i f f e n e d by r i n g f r a m e s , s t r i n g e r s a n d f l o o r b e a m s of a r b i t r a r y con-
    f i g u r a t i o n s . The c a b i n i n t e r i o r i s covered w i t h a c o u s t i c t r e a t m e n t a n d
    t r i m . The p r o p e l l e r n o i s e c o n s i s t s o f a series o f t o n e s a t h a r m o n i c s o f
    t h e b l a d e passage frequency.




17. Kev Words (Selected by Author(s))                                18. Distribution Statement
    f i r c r a f t Interior N o i s e




19. Security Classif. (of this report)        20. Security Classif. (of this page)             21. No. of Pages      22. Price
    Unclassified                                  Unc 1ass i f i e d                                58
```
