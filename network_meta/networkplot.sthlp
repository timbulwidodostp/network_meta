{smcl}

{p}{helpb network_graphs: Return to main help page for the network graphs package}

{hline}
help for {hi:networkplot} command
{hline}

{title:Title}

{p 4 4 2}
Plot for networks of interventions in terms of nodes and edges


{title:Description}

{p 4 4 1}
The {cmd:networkplot} command plots a network of interventions using nodes and edges.
Nodes represent the competing treatments and edges represent the available direct comparisons between pairs of treatments. 
It allows for weighting and coloring options for both nodes and edges according to pre-specified characteristics {help network_graphs##Chaimani2013:(Chaimani, 2013)}.
The use of weighting and coloring schemes can reveal important differences in the characteristics of treatments or comparisons;
the latter can be an indication of potential violation of the assumption underlying network meta-analysis {help network_graphs##Salanti2012:(Salanti, 2012)},
{help network_graphs##Jansen2013:(Jansen, 2013)}.



{title:Syntax}

{p 8 17 2}
{cmd:networkplot} 
{it:varlist}
[{cmd:if} {it:exp}]
[{cmd:in} {it:range}]
[{cmd:,} 
{cmdab:now:eight}
{cmdab:nodew:eight(}{it:study|arm weightvar(s) method})
{cmdab:edgew:eight(}{it:weightvar method})
{cmdab:lab:els(}{it:string}{cmd:)}
{cmdab:labs:ize(}{it:string}{cmd:)}
{cmdab:nodec:olor(}{it:string}{cmd:)}
{cmdab:edgec:olor(}{it:edge_color|by groupvar pool_method}{cmd:)}
{cmdab:bylev:els(}{it:#}{cmd:)}
{cmdab:bycol:ors(}{it:string}{cmd:)}
{cmdab:edgepat:tern(}{it:string}{cmd:)}
{cmdab:plot:reg(}{it:string}{cmd:)}
{cmdab:asp:ect(}{it:#}{cmd:)}
{cmdab:edgesc:ale(}{it:#}{cmd:)}
{cmdab:nodesc:ale(}{it:#}{cmd:)}
{cmdab:tit:le(}{it:string}{cmd:)}]

{p 4 4 2}

{phang}
The networkplot command requires in [{it:varlist}] to declare the following:

{phang}
{it:t1} and  {it:t2} (numeric or string) the codes of two treatments being compared in every observation of the dataset.
 
{phang}{ul:Important note:} The networkplot command only reads datasets that have been prepared with {helpb network setup} or {helpb network import} in the pairs format{p_end}

{title:Options}

{phang}
{cmdab:now:eight} specifies that all nodes and edges (if {it:nodeweight()} and {it:edgeweight()} have not been specified) are of equal size and thickness. 
By default, both nodes and edges are weighted according to the number of studies involved in each treatment or comparison respectively.

{phang}
{cmdab:nodew:eight(}{it:study|arm weightvar(s) sum|mean}) specifies a study-level variable or two arm-level variables according to which nodes are weighted.

{phang}
{cmdab:edgew:eight(}{it:weightvar sum|mean}) specifies a variable according to which edges are weighted.

{p 8 1 1}
{cmd:{it:sum|mean}} specifies whether the sum ({bf:the default}) or the mean of the values of {it:weightvar} is used to weight the nodes and/or edges.

{phang}
{cmdab:lab:els(}{it:string}{cmd:)} specifies the names for treatments in numerical or alphabetical order separated by space. These labels are displayed in the network plot. 

{phang}
{cmdab:labs:ize(}{it:string}{cmd:)} specifies the size of the font for treatment labels (see {helpb scatter}). The {bf:the default} size is {bf:small}. 

{phang}
{cmdab:nodec:olor(}{it:string}{cmd:)} specifies the color for all nodes (see {helpb scatter}). The {bf:the default} color is {bf:blue}.

{phang}
{cmdab:edgec:olor(}{it:edge_color|by groupvar pool_method}{cmd:)} 

{p 8 8 1}
{cmd:{it:edge_color}} specifies the color for all edges (see {helpb line}). The {bf:the default} color is {bf:black}.

{p 8 8 1}
{cmd:{it:by}} specifies that edges are colored according to the bias level of each comparison. 

{p 8 8 1}
{cmd:{it:groupvar}} is a variable that contains bias scores for each observation (i.e. study data such as effect size) and 
can be a numeric variable coded as 1=Low risk, 2=Unclear risk, 3=High risk, or a string variable with values "l(ow)", "u(nclear)", "h(igh)". By default,
a three-level {it:groupvar} is assumed. More or less than three levels with user-specified colors are also allowed if the options {it:bylevels} and {it:bycolors}
have been specified.

{p 8 1 1}
{cmd:{it:pool_method}} specifies the method to estimate the risk of bias level for the summary estimate of each comparison and can be one of the following:

{p 12 1 1}
{cmd:{it:mode}} the most prevalent bias level within each comparison is the comparison-specific bias level ({bf:the default}).  

{p 12 1 1}
{cmd:{it:mean}} the average bias level of each comparison is the comparison-specific bias level.

{p 12 1 1}
{cmd:{it:wmean weightvar}} the weighted (according to the {it:weightvar}) average bias level of each comparison is the comparison-specific bias level.

{p 12 1 1}
{cmd:{it:max}} the maximum bias level observed within each comparison defines the comparison-specific bias level.

{p 12 1 1}
{cmd:{it:min}} the minimum bias level observed within each comparison defines the comparison-specific bias level.

{phang}
{cmdab:bylev:els(}{it:#}{cmd:)} specifies the number of levels for the {it:groupvar} in {it:edgecolor()} when there are more than 3 bias levels. In this
case the {it:groupvar} variable can be only numeric and the option {it:bycolors} is required.

{phang}
{cmdab:bycol:ors(}{it:string}{cmd:)} specifies the colors for each bias level of the {it:groupvar} in the respective order (the option {it:bylevels()} is required). 
 
{phang}
{cmdab:edgepat:tern(}{it:string}{cmd:)} specifies the pattern for all edges (see {helpb line}).

{phang}
{cmdab:plot:reg(}{it:string}{cmd:)} specifies options for the region of the network plot (see {helpb graph}). The {bf:the default} option is {bf:margin(15 15 10 10)}.

{phang}
{cmdab:asp:ect(}{it:#}{cmd:)} specifies the aspect ratio for the region of the network plot (see {helpb aspectratio}). The {bf:default} is {bf:1}.

{phang}
{cmdab:edgesc:ale(}{it:#}{cmd:)} specifies a real number that is used to scale all edges

{phang}
{cmdab:nodesc:ale(}{it:#}{cmd:)} specifies a real number that is used to scale all nodes

{phang}
{cmdab:tit:le(}{it:string}{cmd:)} specifies the title of the plot.


{title:Examples}


{phang}{cmd:. networkplot treat1 treat2, noweight}

{phang}{cmd:. networkplot treat1 treat2, nodew(study number_patients) edgew(baseline_risk)}

{phang}{cmd:. networkplot treat1 treat2, edgecolor(by wmean inverse_variance) labels(Placebo Aspirin Dipyridamole)}

{phang}{cmd:. networkplot treat1 treat2, edgecolor(by inverse_variance) bylevels(5) bycolors(green blue magenta sienna purple)}

{phang}

{p}{helpb network_graphs: Return to main help page for the network graphs package}


{phang}
