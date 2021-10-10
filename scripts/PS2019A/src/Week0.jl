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
@rimport var"data.table" as dt


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


popdf_nm |> browse

Symbol(names(popdf_nm)[1])

popdf14 = copy(popdf_nm)
for i in names(select(select(popdf_nm, Not(:CTYNAME)), Not(:POPESTIMATE2014)))
    select!(popdf14, Not(Symbol(i)))
end


DataFramesMeta.rename!(popdf14, [:CTYNAME => :county_name])


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
dfnm16 = filter(x -> ((x.year == 2016) ),
                    filtered1620df)

other16 = filter(x-> x.candidate ==  "OTHER" && x.party == "OTHER", dfnm16 )
rep16 = filter(x-> x.candidate ==  "DONALD TRUMP" && x.party == "REPUBLICAN", dfnm16 )
dem16 = filter(x-> x.candidate ==  "HILLARY CLINTON" && x.party == "DEMOCRAT", dfnm16 )

otherrep16 = innerjoin(other16[!,[:county_name, :candidatevotes, :candidateproportions]],
                 rep16[!,[:county_name, :candidatevotes, :candidateproportions]],
                 on =:county_name,
                 renamecols = "_Presidential2016_Other" => "_Presidential2016_DonaldTrump")


tidy16 = innerjoin(otherrep16, dem16[!,[:county_name, :candidatevotes, :candidateproportions]], on = :county_name)

DataFramesMeta.rename!(tidy16, [:candidatevotes => "candidatevotes_Presidential2016_HillaryClinton",
                              :candidateproportions => "candidateproportions_Presidential2016_HillaryClinton"])

tidy16[!,"popSizes_2016"] = other16[!,"popsizes"]
tidy16[!, "totalVotes_2016"] = other16[!, "totalvotes"]

dfnm20 = filter(x -> ((x.year == 2020) ),
                filtered1620df)

rep20 = filter(x-> x.candidate ==  "DONALD J TRUMP" && x.party == "REPUBLICAN", dfnm20 )
dem20 = filter(x-> x.candidate ==  "JOSEPH R BIDEN JR" && x.party == "DEMOCRAT", dfnm20 )
tidyrepdem20 = innerjoin(rep20[!,[:county_name, :candidatevotes, :candidateproportions]],
                 dem20[!,[:county_name, :candidatevotes, :candidateproportions]],
                 on =:county_name,
                 renamecols = "_Presidential2020_DonaldTrump" => "_Presidential2016_JosephBiden")

tidyrepdem20[!,"popSizes_2020"] = rep20[!,"popsizes"]
tidyrepdem20[!, "totalVotes_2020"] = rep20[!, "totalvotes"]


tidy1620 = innerjoin(tidy16, tidyrepdem20, on = :county_name) 


# ** Senate 2014-2020 data

# *** 2014
senate14df = let 
    County = ["Bernalillo","Catron", "Chaves", "Cibola", "Colfax", "Curry",
    "DeBaca", "Dona Ana", "Eddy", "Grant", "Guadalupe", "Harding", "Hidalgo",
    "Lea", "Lincoln", "Los Alamos", "Luna", "McKinley", "Mora", "Otero", "Quay",
    "Rio Arriba", "Roosevelt", "Sandoval", "San Juan", "San Miguel", "Santa Fe",
    "Sierra", "Socorro", "Taos", "Torrance", "Union", "Valencia"]

    Senators = ("ALLEN E. WEH (REP)", "TOM UDALL (DEM)")

    CountySenatorsPairs = ["Bernalillo"=> [73751, 97760], "Catron" => [1156,543],
                           "Chaves" => [8801,4183], "Cibola" => [2045,3638], "Colfax" => [1878, 2394],
                           "Curry"=> [5612, 2412], "De Baca"=> [462, 321], "Dona Ana"=> [18150, 23111],
                           "Eddy"=> [7545, 4044], "Grant"=> [3863, 5323], "Guadalupe"=> [455, 1378],
                           "Harding"=> [256, 260], "Hidalgo"=> [667, 784], "Lea"=> [6739, 2360],
                           "Lincoln"=> [4035, 2131], "Los Alamos"=> [3534, 4434], "Luna"=> [2388, 2467],
                           "McKinley"=> [3481, 11334], "Mora"=> [585, 1528], "Otero"=> [8158, 4609],
                           "Quay"=> [1557, 1125], "Rio Arriba"=> [2503, 7665], "Roosevelt"=> [2531, 1254],
                           "San Juan"=> [18137, 11904], "San Miguel"=> [1842, 6199], "Sandoval"=> [18558,
                                                                                                   20140], "Santa Fe"=> [11418, 37657], "Sierra"=> [2120, 1575], "Socorro"=> [2152,
                                                                                                                                                                              3137], "Taos"=> [2026, 8698], "Torrance"=> [2624, 1999], "Union"=> [874, 505],
                           "Valencia" => [9194, 9537]] |> Dict


    CountySenatorsPreDf= Dict{String, Vector{Float64}}()

    for (k,v) in pairs(CountySenatorsPairs)
        CountySenatorsPreDf[k] = Float64[float(v[1]),
                                         float(v[2]),
                                         float(v[1]) + float(v[2]),
                                         float(v[1])/(float(v[1]) + float(v[2])),
                                         float(v[2])/(float(v[1]) + float(v[2]))]
    end



    senate2014 = rcopy(dt.transpose(DataFrame(CountySenatorsPreDf),
                                    var"keep.names" = "col"))

    DataFramesMeta.rename!(senate2014, [:V1=>"Senate 2014: ALLEN E. WEH (REP)",
                                        :V2=>"Senate 2014: TOM UDALL (DEM)",
                                        :V3=>"Senate 2014: Total",
                                        :V4=>"Senate 2014 percentage: ALLEN E. WEH (REP)",
                                        :V5=>"Senate 2014 percentage: TOM UDALL (DEM)"])
    senate2014
end


senate14df[!, :county_name] = map(x->rcopy(stri_trans_toupper(x)), senate14df.col)
select!(senate14df, Not(:col))

# *** 2020

senate20df = let

    County = ["Bernalillo","Catron", "Chaves", "Cibola",
    "Colfax", "Curry", "De Baca", "Dona Ana", "Eddy", "Grant", "Guadalupe",
    "Harding", "Hidalgo", "Lea", "Lincoln", "Los Alamos", "Luna", "McKinley",
    "Mora", "Otero", "Quay", "Rio Arriba", "Roosevelt", "Sandoval", "San Juan",
    "San Miguel", "Santa Fe", "Sierra", "Socorro", "Taos", "Torrance", "Union",
              "Valencia"]

    Ben_Ray_Lujan_DEM_percent = [56.7, 23.5, 27.6, 50.5, 42.3, 28.6, 25.2, 57.6,
    23.2, 51.4, 57, 31.2, 41.3, 19.6, 28.4, 57.1, 43, 65.2, 62.3, 34.2, 31.5,
    64, 27.2, 49.5, 33.2, 67.9, 73.9, 35.9, 49.5, 75.8, 30, 22.5, 41.5]

   Ben_Ray_Lujan_DEM_Votes = [178881, 543, 6143, 4478, 2549, 4261, 228, 46918,
       5301, 7377, 1240, 157, 793, 4018, 2915, 7018, 3425, 17129, 1674, 7987,
       1214, 10615, 1774, 37782, 17250, 7817, 60432, 2127, 3529, 12986, 2179,
       399, 13344]

   Mark_Ronchetti_GOP_percent = [40.6, 73.5, 70.2, 47.2, 55.1, 67.7, 72.3, 38.9,
       74.8, 46.1, 41.2, 67.8, 56.2, 77.9, 69.3, 39.6, 54.2, 31.7, 35.6, 62.7,
       66.1, 34.3, 69, 48.1, 63.8, 30.8, 24.2, 61.7, 47.5, 22.1, 67.5, 74.6,
       56.2]

   Mark_Ronchetti_GOP_Votes = [128042, 1694, 15624, 4187, 3314, 10094, 653,
       31698, 17079, 6610, 898, 341, 1079, 15950, 7102, 4866, 4319, 8329, 957,
       14627, 2543, 5689, 4505, 36666, 33145, 3545, 19814, 3653, 3384, 3793,
       4904, 1323, 18056]

   Bob_Walsh_LIB_percent = [2.7, 3, 2.1, 2.3, 2.6, 3.8, 2.4, 3.5, 2, 2.5, 1.8,
       1, 2.4, 2.5, 2.2, 3.4, 2.8, 3.1, 2, 3.1, 2.4, 1.6, 3.9, 2.4, 3.1, 1.4,
       1.9, 2.4, 2.9, 2, 2.5, 2.9, 2.3]

   Bob_Walsh_LIB_Votes = [8606, 69, 475, 205, 156, 561, 22, 2890, 463, 352, 39,
       5, 47, 508, 230, 415, 222, 809, 55, 715, 91, 271, 252, 1841, 1588, 159,
       1563, 140, 210, 346, 184, 51, 731]

   senate2020vals = zip([Ben_Ray_Lujan_DEM_percent, Ben_Ray_Lujan_DEM_Votes,
                 Mark_Ronchetti_GOP_percent, Mark_Ronchetti_GOP_Votes,
                 Bob_Walsh_LIB_percent, Bob_Walsh_LIB_Votes]...)

    senate2020 = begin
       Dict(Pair(k,[v...]) for (k,v) in zip(County, senate2020vals)) |>
           DataFrame |> df -> dt.transpose(df, var"keep.names" = "col") |> rcopy
   end

   renaming_scheme = [:V1=>"Senate 2020 percentage: Ben Ray Lujan (DEM)",
    :V2=>"Senate 2020: Ben Ray Lujan (DEM)",
    :V3=>"Senate 2020 percentage: Mark Ronchetti (REP)",
    :V4=>"Senate 2020: Mark Ronchetti (REP)",
    :V5=>"Senate 2020 percentage: Bob Walsh (LIB)",
    :V6=>"Senate 2020: Bob Walsh (LIB)"]

   DataFramesMeta.rename!(senate2020, renaming_scheme)

   senate2020
end

senate20df[!, :county_name] = map(x->rcopy(stri_trans_toupper(x)), senate20df.col)
select!(senate20df, Not(:col))

# Putting everything together
prefinaltidy = innerjoin(tidy1620, senate14df, on = :county_name)
finaltidy = innerjoin(prefinaltidy, senate20df, on = :county_name)
finaltidypop14too = innerjoin(finaltidy, popdf14, on = :county_name)


popdf14
browse(finaltidypop14too)

# TODO: add population size 2014
# ** Saving
R"write.csv($df_nm, file = '../../../data/nm_counties.csv'  )"
R"write.csv($filtered1620df, file = '../../../data/nm_counties_1620.csv'  )"
R"write.csv($finaltidypop14too, file = '../../../data/nm_counties_tidy.csv'  )"


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
