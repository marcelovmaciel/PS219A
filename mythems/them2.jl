import Pkg
Pkg.activate("../scripts/PS2019A")
using DataFrames,Distributions
import FreqTables as Freq
using FloatingTableView
using RCall

@rlibrary readxl

((0.99 * 0.8)
+ (0.01 * 0.1)
+ (0.01 * 0.9)
 + (0.99 * 0.2))

# * Them 3.4

winningprob(n,k,p) = sum(pdf(Binomial(n,p), i) for i in k:n)


# 1. p = 0.5, n = 7, k = 4, thus Pr(X>=k) =

winningprob(7,4,0.5)

# 2. p = 0.5, n = 6, k = 4, thus Pr(X>=k) =
winningprob(6,4,0.5)
# 3. p = 0.5, n = 5, k = 3, thus Pr(X>=k) =
winningprob(5,3,0.5)
# 4.  p = 0.5, n = 4, k = 3, thus Pr(X>=k)
winningprob(4,3,0.5)
# 5. p = 0.5, n = 3, k = 3, thus Pr(X>=k) =
winningprob(3,3,0.5)


# * Them 3.7

2 * 0.6 - 1 * 0.4

35 * 0.1 - 2*0.9

(35 * 100 * 0.1)


# * 3.8
0.1/0.15
0.06/0.1

# * Them 4.4
pdf(Binomial(120,0.5), 60)


# * Them 3.9
using DataFrames
import FreqTables as Freq
using RCall
@rlibrary readxl
data2= DataFrame(rcopy(read_excel("them3.9.xlsx", sheet = "Sheet3", skip=1 )))

f = Freq.freqtable(data2, :Pres, :House)
Freq.prop(f)
