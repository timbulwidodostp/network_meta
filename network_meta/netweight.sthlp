{smcl}

{p}{helpb network_graphs: Return to main help page for the network graphs package}

{hline}
help for {hi:netweight} command
{hline}

{title:Title}

{p 4 4 2}
Contribution of each direct comparison in network meta-analysis estimates


{title:Description}

{p 4 4 1}
When performing a network meta-analysis each direct comparison contributes to the estimation of each network meta-analytic summary effect by a different weight
{help network_graphs##Lu2011:(Lu, 2011)},
{help network_graphs##Krahn2013:(Krahn, 2013)}.
Identifying comparisons with large or small contributions is of great interest and enhances the understanding of the evidence flow.
The contributions of the different pieces of evidence within a network have also been used in the evaluation of the quality of evidence from network meta-analysis {help network_graphs##Salanti2014:(Salanti, 2014)}.
These contributions are obtained as complicated functions of a) the structure of the network b) the variances of each pairwise direct summary effect.

{p 4 4 1}
The {cmd:netweight} command calculates all direct pairwise summary effect sizes with their variances,
creates the design matrix and estimates the percentage contribution of each direct comparison to the network summary estimates and in the entire network.
Then, it produces the contribution plot that uses weighted squares to represent the respective contributions.
The command also can combine the estimated contributions with a particular trial-level characteristic
(e.g. the risk of bias of the studies) and produces a bar graph showing the percentage of information in each network estimate that corresponds to the different levels of the characteristic.    


{title:Syntax}

{p 8 17 2}
{cmd:netweight} 
{it:varlist}
[{cmd:if} {it:exp}]
[{cmd:in} {it:range}]
[{cmd:,} 
{cmd:random}
{cmd:fixed}
{cmdab:tau:2(}{it:#}{cmd:)}
{cmdab:bar:graph(}{it:by groupvar pool_method}{cmd:)}
{cmdab:bylev:els(}{it:#}{cmd:)}
{cmdab:bycol:ors(}{it:string}{cmd:)}
{cmdab:notab:le}
{cmdab:sc:ale(}{it:string}{cmd:)}
{cmdab:noval:ues}
{cmdab:nost:udies}
{cmdab:asp:ect(}{it:string}{cmd:)}
{cmdab:col:or(}{it:string}{cmd:)}
{cmdab:symb:ol(}{it:string}{cmd:)}
{cmdab:text:size(}{it:string}{cmd:)}
{cmdab:nopl:ot}
{cmdab:tit:le(}{it:string}{cmd:)}
{cmdab:noy:matrix}
{cmdab:nov:matrix}
{cmdab:nox:matrix}
{cmdab:noh:matrix}
{cmdab:exp:ort(}{it:string}{cmd:)}
{cmdab:ref:erence(}{it:string}{cmd:)}
{cmdab:treatex:clude(}{it:string}{cmd:)}
{cmdab:baropt:ions(}{it:string}{cmd:)}
{cmdab:thres:hold(}{it:string}{cmd:)}
]

{p 4 4 2}

{p 4 4 1}
The netweight command requires in {it:varlist} to specify the following variables:

{pstd}{it:ES} the effect sizes for every treatment comparison defined in the dataset (for ratio measures such as odds ratio, risk ratio, hazard ratio, etc. the effect sizes in {it:ES} should be in logarithmic scale; e.g. log-odds ratio, log-risk ratio){p_end} 

{phang}{it:se} the standard errors of the effect sizes in {it:ES}{p_end}
 
{phang}{it:t1} and  {it:t2} (numeric or string) the codes of the two treatments compared in each observation{p_end} 

{phang}{ul:Important note:} The netweight command only reads datasets that have been prepared with {helpb network setup} or {helpb network import} in the pairs format{p_end}

{title:Options}

{phang}
{cmd:random} specifies that the random effects model is used for the estimation of all direct pairwise summary effects ({bf:the default}).
	
{phang}
{cmd:fixed} specifies that the fixed effect model is used for the estimation of all direct pairwise summary effects.

{phang}
{cmdab:tau:2(}{it:#}{cmd:)} specifies a real non-negative number that is used as the heterogeneity variance common for all comparisons.

{phang}
{cmdab:bar:graph(}{it:by groupvar pool_method}{cmd:)} specifies that a bar-graph is drawn instead of the contribution plot.
The bars are colored according to the bias level (see option edgecolor() of the networkplot command) and their length is proportional to the percentage contribution of each direct comparison to the network estimates
{help network_graphs##Salanti2014:(Salanti, 2014)}. For a description of the {it:groupvar} and {it:pool_method} see the options for the {helpb networkplot} command.

{phang}
{cmdab:bylev:els(}{it:#}{cmd:)} and {cmdab:bycol:ors(}{it:string}{cmd:)} the same options as in the {helpb networkplot} command.

{phang}
{cmdab:notab:le} skips the display of the output results.

{phang}
{cmdab:sc:ale(}{it:string}{cmd:)} specifies a real number that is used to scale the weighted squares in the contribution plot.

{phang}
{cmdab:noval:ues} suppresses the display of the percentage contributions in the contribution plot.

{phang}
{cmdab:nost:udies} suppresses the display of the number of included studies in each comparison in the contribution plot.

{phang}
{cmdab:asp:ect(}{it:string}{cmd:)} specifies the aspect ratio for the region of the contribution plot (see {helpb aspectratio}).

{phang}
{cmdab:col:or(}{it:string}{cmd:)} specifies the color of the squares in the contribution plot (see {helpb scatter}).

{phang}
{cmdab:symb:ol(}{it:string}{cmd:)} specifies an alternative symbol for the weighted squares in the contribution plot (see {helpb scatter}).

{phang}
{cmdab:text:size(}{it:string}{cmd:)} specifies the size of the text for the contribution plot.

{phang}
{cmdab:nopl:ot} skips the display of the contribution plot.

{phang}
{cmdab:tit:le(}{it:string}{cmd:)} specifies the title of the contribution plot.

{phang}
{cmdab:noy:matrix} skips the display of the vector containing the direct relative effects.

{phang}
{cmdab:nov:matrix} skips the display of the matrix containing the variances of the direct relative effects.

{phang}
{cmdab:nox:matrix} skips the display of the design matrix.

{phang}
{cmdab:noh:matrix} skips the display of the hat matrix that maps the direct estimates into the network estimates.

{phang}
{cmdab:exp:ort(}{it:string}{cmd:)} specifies the path for an excel file where results are saved.

{phang}
{cmdab:ref:erence(}{it:string}{cmd:)} specifies a reference treatment for the bar-graph. Only comparisons containing the reference treatment are plotted.

{phang}
{cmdab:treatex:clude(}{it:string}{cmd:)} specifies treatments to be excluded from the bar-graph. Comparisons containing these treatmenta are not plotted.

{phang}
{cmdab:baropt:ions(}{it:string}{cmd:)} specifies additional valid options for the bar-graph.

{phang}
{cmdab:thres:hold(}{it:string}{cmd:)} specifies a vertical line drawn at a specific percentage contribution point. 

{title:Saved results}

{synoptset 20 tabbed}{...}
{synopt:{cmd:e(y)}}the vector with all direct pairwise pooled effects{p_end}
{synopt:{cmd:e(v)}}the squared matrix with the variances of all direct pairwise pooled effects in the diagonal and 
	a large variance(10000) for all indirect comparisons{p_end}
{synopt:{cmd:e(x)}}the design matrix for all direct and indirect comparisons {p_end}
{synopt:{cmd:e(h)}}the squared matrix with the contribution of all direct comparisons
	in each network meta-analsysis summary effect{p_end}
{synopt:{cmd:e(p)}}the squared matrix with the percentage contribution of all direct comparisons
	in each network meta-analsysis summary effect{p_end}	


{title:Examples}

{phang}{cmd:. netweight lnOR selnOR treat1 treat2, scale(0.5) novalues}

{phang}{cmd:. netweight lnOR selnOR treat1 treat2, color(blue) symbol(circle) nostudies aspect(0.8)}

{phang}{cmd:. netweight lnOR selnOR treat1 treat2,fixed noplot}

{phang}{cmd:. netweight lnOR selnOR treat1 treat2,tau2(0.2) bar(by blinding mean)}


{title:Multi-arm trials}

{p 0 0 0}
The current version of the netweight command does not account for the correlation in the direct effect sizes from multi-arm trials.

{phang} 

{p}{helpb network_graphs: Return to main help page for the network graphs package}

{phang} 

