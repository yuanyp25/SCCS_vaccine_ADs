library(forestplot)
library(grid)

variable <- c(NA, 'Day 0','Day 1','Day 2','Subgroup analysis of day 0','Male','Female','Moderna','Pfizer','Excluding patients with\nCOVID-19 infection')

mean_values <- df$confidence_upper[2]
lower_CI <- df$confidence_upper[3]  
upper_CI <- df$confidence_upper[4]    


CI_95 <- df$confidence_upper[5]

REF_EVENT <- df$confidence_upper[6]
RISK_EVENT <- df$confidence_upper[7]

plot <- forestplot(
  labeltext = cbind(variable, RISK_EVENT, REF_EVENT, CI_95),  
  mean = c( NA, mean_values),
  lower = c( NA, lower_CI),
  upper = c( NA, upper_CI),
  xlab = "IRR (95%CI)",
  boxsize = 0.13,
  zero = 5,
  graph.pos = 5,
  is.summary = c(TRUE, F,F,F,T,rep(FALSE, 5)),
  xticks = c(3, 18,29,40),
  clip = c(3, 18,29,40),
  col = fpColors(box = "#0077BE", lines = "#0077BE", zero = "#87CEEB"),
  lwd.zero = 1,
  lwd.ci = 1,
  lwd.xaxis = 2,
  lty.ci = 7,
  ci.vertices = TRUE,
  ci.vertices.height = 0.1,
  lineheight = unit(1.5, 'cm'),
  line.margin = unit(8, 'mm'),
  colgap = unit(15, 'mm'),
  graphwidth = unit(6, "cm"),
  txt_gp = fpTxtGp(                
    label = gpar(cex = 0.9),      
    ticks = gpar(cex = 1),         
    xlab = gpar(cex = 1)     
  ),  
  hrzl_lines = list(
    "1" = gpar(lty = 1, lwd = 2),
    "2" = gpar(lty = 2, lwd = 1),
    "6" = gpar(lty = 2, lwd = 1),
    "11" = gpar(lwd = 2, lty = 1, columns = c(1:4))
  ),
  align = c("l", "c", "c","c"),
  new_page = TRUE  
)

print(plot)