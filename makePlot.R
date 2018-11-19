
# Make first graphic in the same vein as reddit
ggplot(data = eloPop, aes(x = PopTotal, y = elo17, col = LEx)) + geom_point(size = 1.5) + 
  scale_x_continuous(trans = "log10", breaks = 100 * (10^(1:7)), labels = comma) + 
  theme_tufte(base_size = 15) + xlab("Population") + ylab("Elo Rating") + geom_smooth(se = T) + 
  scale_color_gradient2(midpoint = mean(eloPop$LEx, na.rm = T), low = "blue", mid = "white", 
                        high = "darkred", space = "Lab")
if (savePlots) {
  ggsave(filename = paste0("plots/", gsub("[^[:alnum:]=\\.]", "", lubridate::now()), 
                           ".pdf"), device = cairo_pdf, units = "cm", width = 34, height = 20)
}

# Kendall Correlation
cor.test(eloPop$elo17, eloPop$PopTotal, method = "kendall")
# Marginal Plot
p <- ggplot(eloPop, aes(PopTotal, elo17)) + geom_point() + theme_tufte(ticks = F) + 
  theme(axis.title = element_blank()) + scale_x_continuous(trans = "log10", breaks = 100 * 
                                                             (10^(1:7)), labels = comma)
ggMarginal(p, type = "density", fill = "transparent")
