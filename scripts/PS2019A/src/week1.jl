using DataFrames, DataFramesMeta, Distributions
using FloatingTableView
#using GLMakie
using RCall
using StatsBase
using Base.Filesystem
import FreqTables as Freq
@rlibrary readr
@rlibrary stringy
@rlibrary readxl
@rlibrary ggplot2 

data= DataFrame(rcopy(read_csv("../../../data/nm_counties_1620.csv")))

browse(data)




data2= DataFrame(rcopy(read_excel("../../../data/cali2012-2016.xlsx", sheet = "Sheet1")))



excel_sheets("../../../data/cali2012-2016.xlsx")



datacols = names(data2)


d3 = dropmissing(data2)





x = [1.52, 1.6, 1.57, 1.6, 1.75, 1.63, 1.55, 1.63, 1.55, 1.65, 1.55, 1.65, 1.6,
1.68, 2.5, 1.52, 1.65, 1.65]



using GLMakie 
f = hist(x, bins = 15)

GLMakie.save("../../../mythems/histogram.png",f)
