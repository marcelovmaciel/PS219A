import Pkg
Pkg.activate("../")

using DataFrames, DataFramesMeta, Distributions
using FloatingTableView
#using GLMakie
using RCall
using StatsBase
using Base.Filesystem
import FreqTables as Freq
@rlibrary readr
using HypothesisTests
using LinearAlgebra

dataw7= DataFrame(rcopy(read_csv("../../../data/mythem7.csv")))


proportions = [ccdf(Normal(x["Average GPA"], x["stdeviationGPA"]), 3.25) for x in eachrow(dataw7)]
argmax(proportions)

honors_number=[x["Count of GPA"] *  ccdf(Normal(x["Average GPA"], x["stdeviationGPA"]), 3.25) for x in eachrow(dataw7)]
argmax(honors_number)
