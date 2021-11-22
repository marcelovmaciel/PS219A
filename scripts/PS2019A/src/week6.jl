import Pkg
Pkg.activate("../")

using DataFrames, DataFramesMeta, Distributions
using FloatingTableView
#using GLMakie
using RCall
using StatsBase
using Base.Filesystem
import FreqTables as Freq
@rlibrary readxl
using HypothesisTests
using LinearAlgebra

data2= DataFrame(rcopy(read_excel("../../../data/them18-3.xlsx", sheet = "Sheet1" )))


data = data2[1:end-2, 1:end]

#data |> browse






puredata = select(data, Not(:___1)) |> dropmissing
firstthird = dropmissing(data)[!,"1-122"]
secondthird = dropmissing(data)[!,"123-244"]
thirdthird = dropmissing(data)[!,"244-366"]

E = map(x->122*x/366, [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31])


function chisquare_pvalue(col,e= E)
    test_statistic = sum(((col .-e).^2)./e)

    pvalue = ccdf(Chisq(length(col)-1),test_statistic)
    return(test_statistic,pvalue)
end


chisquare_pvalue(secondthird, no

ChisqTest(firstthird.|> Int,  normalize(E,1))


secondthird
R"chisq.test($puredata, p = $(normalize(E,1)))"
