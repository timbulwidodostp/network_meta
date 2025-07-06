{smcl}
{* *! version 3.1  13jul2015}{...}
{vieweralsosee "mvmeta" "mvmeta"}{...}
{vieweralsosee "mvmeta demonstration" "mvmetademo_run"}{...}
{title:Title}

{phang}{hi:mvmeta} {hline 2} A demonstration for the mvmeta package in Stata: Getting the data into mvmeta format


{title:Introduction}

{pstd}{cmd:mvmeta} expects the data to be organized with one line per study,
with each line containing the estimates and their variances for that study.
The estimates must be named as a common stub followed by a unique ending, and
the variances must be named as a (different) common stub followed by a
repeated ending.  Ideally, covariances are also included, named as the
variance stub followed by two endings. 

{pstd}Let's make that more concrete by inputting the {cmd:p53} data. 
These data are described in the
{help mvmetademo_run##p53:main demonstration}.  The data are the estimated
log hazard-ratios (lnHR) for mutant versus normal p53 gene for two outcomes.

{pstd}The data for overall survival look like the following:

            study estimate  std.error
                1     -.18        .56  
                2      .79        .24  
                3      .21        .66  
                4     -.63        .29  
                5     1.01        .48  
                6     -.64         .4  
		
{pstd}The corresponding data for disease-free survival 
(which was only reported in 3 studies) look like the following:
        
            study estimate  std.error
                1     -.58        .56  
                4    -1.02        .39  
                6     -.69         .4  

{pstd}We enter these using lnHR as the stub for the log hazard-ratios and
selnHR as a stub for the standard errors, and we use abbreviations os for
overall survival and dfs for disease-free survival:

        {bf:{stata clear}}
        {bf:{stata input study lnHRos selnHRos lnHRdfs selnHRdfs}}
                    {bf:{stata       1   -.18      .56    -.58       .56}}
                    {bf:{stata       2    .79      .24       .         .}}
                    {bf:{stata       3    .21      .66       .         .}}
                    {bf:{stata       4   -.63      .29   -1.02       .39}}
                    {bf:{stata       5   1.01      .48       .         .}}
                    {bf:{stata       6   -.64       .4    -.69        .4}}
        {bf:{stata end}}

{pstd}Note that we have entered missing values for disease-free survival in
studies 2, 3, and 5.

{pstd}{cmd:mvmeta} requires variables representing the variances.  These must
be named as <stub><ending><ending>. We choose VlnHR as the stub for the
variances, so we type

        {bf:{stata  gen VlnHRosos = selnHRos^2}}

        {bf:{stata  gen VlnHRdfsdfs = selnHRdfs^2}}

{pstd}These data are now in the format required by {cmd:mvmeta} and can be
analyzed as shown in the {help mvmetademo_run##p53:main demonstration}.

{pstd}If we knew the within-study covariances, we could have input them
with the main data.  If we also knew the within-study correlations, we could
have input them with the main data (say, as variable corrosdfs) and then
computed the covariances using
{bf:{stata gen VlnHRosdfs = corrosdfs*selnHRos*selnHRdfs}}.
{p_end}
