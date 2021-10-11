import Pkg
Pkg.activate("../scripts/PS2019A")
using Distributions

((0.99 * 0.8)
+ (0.01 * 0.1)
+ (0.01 * 0.9)
 + (0.99 * 0.2))

# * Them 3.4

# 1. p = 0.5, n = 7, k = 4, thus Pr(X>=k) =
(pdf(Binomial(7,0.5), 4) +
    pdf(Binomial(7,0.5), 5) +
    pdf(Binomial(7,0.5), 6) +
    pdf(Binomial(7,0.5), 7)
 )

# 2. p = 0.5, n = 6, k = 4, thus Pr(X>=k) =
(pdf(Binomial(6,0.5), 4) +
    pdf(Binomial(6,0.5), 5) +
    pdf(Binomial(6,0.5), 6)
 )

# 3. p = 0.5, n = 5, k = 3, thus Pr(X>=k) =
(pdf(Binomial(5,0.5), 3) +
    pdf(Binomial(5,0.5), 4) +
    pdf(Binomial(5,0.5), 5)
 )


# 4.  p = 0.5, n = 4, k = 3, thus Pr(X>=k)
(pdf(Binomial(4,0.5), 3) +
pdf(Binomial(4,0.5), 4))


# 5. p = 0.5, n = 3, k = 3, thus Pr(X>=k) =
pdf(Binomial(3,0.5), 3)
