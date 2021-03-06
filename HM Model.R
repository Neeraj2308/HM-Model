#Title: Portfolio Optimization Using R (HM Model) 
#Date: 02nd April 2020
#Author: Neeraj Jain

rm(list = ls())
setwd("/Users/neerajjain/Desktop/HM Model")

#reading Data
price <- read.csv(file = "Data.csv")

#removing NA
price <- price[complete.cases(price), ]

#remove date
price <- price[, -1]

#number of securities
ns <- ncol(price)

#Getting return (we have taken log return)
ret <- apply(log(price), 2, diff)

#expected return and sd
er <- apply(ret, 2, mean) #daily expected return
std <- apply(ret, 2, sd) #daily sd

#covariance matrix
covm <- cov(ret)

#Global minimum variance (gmv) portfolio
Am <- rbind(2*covm, rep(1, ns))
Am <- cbind(Am, c(rep(1, ns), 0))
b <- c( rep(0, ns), 1)

w.gmv <- solve(Am) %*% b 
w.gmv <- w.gmv[-(ns+1), ]  #last value is lambda constraint. Hence not relevant
sum(w.gmv) #sum of weights are 1

#variance of portfolio (Minimum variance)
var.gmv <- t(w.gmv) %*% covm %*% weight.gmv

#expected return on minimum global variance portfolio
ret.gmv <- t(w.gmv) %*% er

##alternate solution
uv <- rep(1, ns) #unit vector
w.gmv2 <- (solve(covm) %*% uv) * c(solve( (t(uv) %*% solve(covm) %*% uv)))


## Efficient Portfolio (ep)
#we derived efficient for given return (ie. minimum risk for given return)

u0 <- er[3] #return that we want to achieved on our portfolio
if(u0 < ret.gmv) {
  message("#u0 should be greater than return on minimum variance portfolio")
}


M <- cbind(er, uv)
B <-  t(M) %*% solve(covm) %*% M
mu.tilde <- c(u0, 1)

w.ep <- solve(covm) %*% M %*% solve(B) %*% mu.tilde

#portfolio expected return
ret.ep <- t(er) %*% w.ep #equals to Auto expected return

#portofolio variance
var.ep <- t(w.ep) %*% covm %*% w.ep  # less than auto var but more than minimum variance portfolio


#Efficient Frontier
#propostion: Linear combination of efficient portfolio is also efficient portfolio

w1 <- .4
w <- seq(from = -.5, to = 1.5, by = .01) #various combination of weights


#first method
eff <- function(w1) {
  z <- w1 * w.gmv + (1 - w1) * w.ep
  c(ret = t(z) %*% er  * 248 , sd = sqrt(t(z) %*% covm %*% z * 248))
}
comb <- cbind(w, t(sapply(w, FUN = eff)))

efficient <- comb[, "ret"] > c(ret.gmv * 248)
xlim <- c(min(comb[, "sd"]), max(comb[, "sd"]))
ylim <- c(min(comb[, "ret"]), max(comb[, "ret"]))
col <- ifelse(efficient, "blue", "red")

plot(comb[ , "ret"] ~ comb[, "sd"], col = col, xlim = xlim, ylim = ylim, 
     xlab = "Portfolio RisK", ylab = "Portfolio Return", pch = 16, main = "Efficient Frontier", 
     cex = .7)

 
#second method (optional)
cov.gmv.ep <- t(w.gmv) %*% covm %*% w.ep    
eff2 <- function(w1) {
  ret.ef <- w1 * ret.gmv + (1 - w1) * ret.ep
  var.ef <- w1^2 * var.gmv + (1 - w1)^2 * var.ep + 2 * w1 * (1-w1) * cov.gmv.ep
  c(w = w1, ret = ret.ef * 248 , sd  = sqrt(var.ef * 248))
}
comb2 <- t(sapply(w, eff2))

### Maximimizing Sharpe Ratio
#SR = (mu - rf) / sigma

rfree <- .00 / 248  #daily risk free return 
#assuming zero risk free rate of interest

w.sr <- solve(covm) %*% (er - rfree) / c(t(uv) %*% solve(covm) %*% (er - rfree))
ret.sr <- t(w.sr) %*% er  
var.sr <- t(w.sr)%*% covm %*% w.sr

#plotting results
comb <- rbind(comb, c(NA, ret.sr * 248, sqrt(var.sr * 248)))
col <- c(ifelse(efficient, "blue", "red"), "green")
xlim <- c(0.15, max(comb[, "sd"]))
ylim <- c(0.10, max(comb[, "ret"]))
cex <- c(ifelse(efficient, .6, .6), 1.2)
pch <- c(rep(1, nrow(comb) - 1), 16)
plot(comb[ , "ret"] ~ comb[, "sd"], col = col, xlim = xlim, ylim = ylim, 
     xlab = "Portfolio RisK", ylab = "Portfolio Return", pch = pch, main = "Efficient Frontier", 
     cex = cex)
abline(a = rfree, b = ret.sr * 248 / sqrt(var.sr * 248), lty = 2) #line of tangency

#to get normal return (use function) (remove hash and run the code)
#ret.f <- function(x) {
# x[-1]/x[-length(x)] - 1
#}

#ret <- apply(price, 2, ret.f)
