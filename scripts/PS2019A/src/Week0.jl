# * Imports
using DataFrames, DataFramesMeta, Distributions
using FloatingTableView
#using GLMakie
using RCall
using StatsBase
using Base.Filesystem
import FreqTables as Freq
@rlibrary readr
@rlibrary stringi

# * County level presidential data stuff

# ** Reading the data
# taken from [[https://electionlab.mit.edu/data][Data | MIT Election Lab]]
const dataspath = "../../../data"

readdir(dataspath)
datapath = dataspath * "/dataverse_files/countypres_2000-2020.csv"
df = DataFrame(rcopy(read_csv(datapath)))

# ** Getting New Mexico stuff
df_nm= @subset(df, :state .== "NEW MEXICO")
browse(df_nm)

@subset(df_nm, (:year .== 2016 .| :year .== 2020))

df_nm1620 = filter(x -> ((x.year == 2016) | (x.year == 2020)), df_nm)

df_nm1620 |> browse

# ** Droping uneeded cols
select!(df_nm1620, Not(:mode))
select!(df_nm1620, Not(:state))
select!(df_nm1620, Not(:state_po))
select!(df_nm1620, Not(:version))

dropmissing!(df_nm1620, [:totalvotes])

# ** Droping candidates below 5%
df_nm1620.candidateproportions = map(x->x.candidatevotes/x.totalvotes, eachrow(df_nm1620))

filtered1620df = @subset(df_nm1620, (:candidateproportions .>= 0.05))

# ** County Population
# taken from
# https://www.census.gov/programs-surveys/popest/technical-documentation/research/evaluation-estimates/2020-evaluation-estimates/2010s-counties-total.html

popdfpath = dataspath * "/co-est2020.csv"
popdf = DataFrame(rcopy(read_csv(popdfpath, locale = locale(encoding = "UTF-8") )))

popdf |> browse

colstokeep = [ "COUNTY", "STNAME", "CTYNAME",
               "POPESTIMATE2014", "POPESTIMATE2016",
               "POPESTIMATE2020"]
popdf = popdf[!,colstokeep]

popdf_nm= @subset(popdf, :STNAME .== "New Mexico")

popdf_nm.STNAME = map(uppercase, popdf_nm.STNAME )

popdf_nm.CTYNAME = map(x->rcopy(stri_trans_toupper(x)), popdf_nm.CTYNAME)

popdf_nm.CTYNAME = map(x->rstrip(replace(x, "COUNTY"=> "")), popdf_nm.CTYNAME)
popdf_nm.CTYNAME = map(x->rstrip(replace(x, "DO\xf1A ANA"=> "DONA ANA")), popdf_nm.CTYNAME)

pop16 = Dict(x.CTYNAME => x.POPESTIMATE2016 for x in eachrow(popdf_nm))

setdiff(Set(keys(pop16) |> collect), Set(unique(filtered1620df.county_name)))
delete!(pop16, "NEW MEXICO")

pop20 = Dict(x.CTYNAME => x.POPESTIMATE2020 for x in eachrow(popdf_nm))
delete!(pop20, "NEW MEXICO")

popsizes = Float64[]

for r in eachrow(filtered1620df)
    if r.year == float(2016)
        popsize = pop16[r.county_name]
        push!(popsizes, popsize)
    elseif r.year == float(2020)
        popsize = pop20[r.county_name]
        push!(popsizes, popsize)
    end
end

filtered1620df.popsizes = popsizes

filtered1620df |> browse

filtered1620df.popsizes

# ** Senate 2014-2020 data





# ** Saving
R"write.csv($df_nm, file = '../../../data/nm_counties.csv'  )"
R"write.csv($filtered1620df, file = '../../../data/nm_counties_1620.csv'  )"



# * garbarge to look later
# # dfnm16 = filter(x -> ((x.year == 2016) ), df_nm)
# dfnm20 = filter(x -> ((x.year == 2020) ), df_nm)

#grouped_data = groupby(df_nm1620, [:year, :county_name])

# totalpergroup = ((combine(grouped_data, :totalvotes => :count)) |>
#     x -> groupby(x, [:year, :county_name]) |>
#     x -> combine(x, :count => unique)
#     )

# combine(gdf,
#                AsTable([:PetalLength, :SepalLength]) =>
#                    x -> std(x.PetalLength) / std(x.SepalLength))

# combine(x->x.candidatevotes/x.totalvotes, dfnm16) |> browse
