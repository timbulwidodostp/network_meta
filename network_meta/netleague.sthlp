{smcl}

{p}{helpb network_graphs: Return to main help page for the network graphs package}

{hline}
help for {hi:netleague} command
{hline}

{title:Title}

{p 4 4 2}
'League table' for networks of intervetnions


{title:Description}

{p 4 4 1}
The {cmd:netleague} command creates a 'league table' showing in the off-diagonal cells the relative treatment effects for all possible pairwise comparisons estimated in a network meta-analysis.
The diagonal cells include the names of the competing treatments in the network, which can be sorted according to a pre-specified order.


{title:Syntax}

{p 8 17 2}
{cmd:netleague} 
[{it:varlist}]
[{cmd:,} 
{cmdab:mvmeta:results}
{cmdab:nomv:meta}
{cmdab:lab:els(}{it:string}{cmd:)}
{cmdab:exp:ort(}{it:string}{cmd:)}
{cmdab:sort:(}{it:string}{cmd:)}
{cmd:eform}
{cmd:nokeep}]

{p 4 4 2}

{p 4 4 1}
The netleague command requires the network meta-analysis summary effects and their uncertainty as input, which can be provided in two different ways:

{p 4 4 1}
1. By running the {cmd:netleague} directly after performing network meta-analysis with {helpb mvmeta} or {helpb network meta}. In that case, the {it:[varlist]} should be omitted.

{pstd}2. By including these summary estimates as variables in the dataset; the following variables should be specified in [varlist]:{p_end}

{phang}{it:ES} the estimated summary effect for each comparison between two treatments in the network (for ratio 
measures such as odds ratio, risk ratio, hazard ratio, etc. the effect sizes in {it:ES} should be in logarithmic scale; e.g. log-odds ratio, log-risk ratio){p_end}

{phang}{it:seES} the standard error of each comparisons's {it:ES}{p_end}

{phang}{it:t1} and {it:t2} (numeric or string) the codes of the two treatments involved in each comparison{p_end} 
{phang}Then, the option {it:nomvmeta} is required.{p_end} 

{title:Options}

{phang}
{cmdab:lab:els(}{it:string}{cmd:)} specifies names for competing treatments in the network, which are displayed in the league table. The treatments should be given in numerical or alphabetical order separated by space.
When the option {it:nomvmeta} has not been specified, then the first treatment in {it:labels()} should be the treatment assumed the reference when running the {cmd:mvmeta} or {cmd:network meta} and the following treatments should be given in numerical or alphabetical order.
	
{phang}
{cmdab:exp:ort(}{it:string}{cmd:)} specifies the path of an excel file where the league table is exported.

{phang}
{cmdab:sort:(}{it:string}{cmd:)} specifies the order for treatments from top to bottom in the league table. When the option {it:nomvmeta} has not been specified, {it:sort()} requires the option {it:labels()}.
When the option nomveta has been specified, the names of treatments should be given as displayed in the dataset in variables t1 and t2. By default, the treatments are ordered alphabetically from bottom to top.
	
{phang}
{cmd:eform} specifies that the results are displayed on the exponential scale.

{phang}
{cmd:nokeep} uppresses storing the league table at the end of the dataset.


{title:Examples}

{phang}{cmd:. netleague, eform export("C:\network.xlsx") nokeep}

{phang}{cmd:. netleague, eform lab(Placebo Aspirin Dipyridamole) sort(Dipyridamole Aspirin Placebo)}

{phang}{cmd:. netleague logor selogor treat1 treat2, nomv eform export("C:\network.xlsx") nokeep}

{phang}{cmd:. netleague logor selogor treat1 treat2, nomv lab(A B C D E) sort(4 5 1 2 3)}

{phang}

{p}{helpb network_graphs: Return to main help page for the network graphs package}


{phang}

  
