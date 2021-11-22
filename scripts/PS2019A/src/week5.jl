import Pkg
Pkg.activate("../")

using DataFrames, DataFramesMeta, Distributions
using FloatingTableView
#using GLMakie
using RCall
using StatsBase
using Base.Filesystem
import FreqTables as Freq
#using HypothesisTests

@rlibrary readxl


men = [62, 81, 87, 87, 93, 98, 99, 105, 114, 125, 127]

mean(men)

women = [78,82,89,95,96,97,98,98,99,
         112,114,114,115,115,117,117,119,120,121,125,130,130,140,148]

df = DataFrame(Dict(:group => vcat(["Man" for i in 1:length(men)],
                                   ["Woman" for i in 1:length(women)]),
                    :singing =>vcat(men,women)))

R"t.test(singing ~ group, data = $df,
 alternative = c('less'))"

# * Them 8.2
data2= DataFrame(rcopy(read_excel("../../../data/them3.9.xlsx", sheet = "Sheet3", skip=1 )))

browse(data2)


f = Freq.freqtable(data2, :Pres, :House)
fprop = Freq.prop(f)

R"chisq.test($f)"

f2 = Freq.freqtable(data2, :Pres, :Senate)
R"chisq.test($f2)"


# * Them 8.8
groups = ["w", "aa", "l", "a or o"]
them88_df_catalist = DataFrame(Dict(
    :year_18 => [76, 12, 7, 5],
    :year_16 => [74,12,9,5],
    :year_14 => [79,11,6,4]))


them88_df_exit = DataFrame(Dict(
    :year_18 => [72, 11, 11, 6],
    :year_16 => [71,12,11,3],
    :year_14 => [75,12,8,6]))


R"t.test($(them88_df_catalist.year_14), $(them88_df_catalist.year_16), paired = TRUE, alternative = 'two.sided')"
R"t.test($(them88_df_catalist.year_16), $(them88_df_catalist.year_18), paired = TRUE, alternative = 'two.sided')"



R"t.test($(them88_df_catalist.year_14), $(them88_df_exit.year_14), paired = TRUE, alternative = 'two.sided')"
R"t.test($(them88_df_catalist.year_16), $(them88_df_exit.year_16), paired = TRUE, alternative = 'two.sided')"
R"t.test($(them88_df_catalist.year_18), $(them88_df_exit.year_18), paired = TRUE, alternative = 'two.sided')"

# R"chisq.test($them88_df_catalist)"

# R"chisq.test($them88_df_exit)"

# R"chisq.test(cbind($(them88_df_catalist.year_14), $(them88_df_exit.year_14)))"
# R"chisq.test(cbind($(them88_df_catalist.year_16), $(them88_df_exit.year_16)))"
# R"chisq.test(cbind($(them88_df_catalist.year_18), $(them88_df_exit.year_18)))"

