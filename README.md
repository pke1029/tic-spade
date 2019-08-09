# Spade
A tool for generating realistic pixelated sphere.

![](demo.gif)

# Model

The model I'm using is given by
- <img src="https://latex.codecogs.com/gif.latex?f(P,D,A)=P\left(\frac{A(1-D)}{D+A(1-D)}A+D\right) " /> 
where
- <img src="https://latex.codecogs.com/gif.latex?P=\text{sphere},D\text{direct light},A\text{ambient light}\in[0,1] " /> 
and the computation is done pointwise.

I derived this model by myself so it's possible that it might be off (feedback welcome). 
