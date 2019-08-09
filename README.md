# Spade
A tool for generating realistic pixelated sphere.

![](demo.gif)

# Model

The model I'm using is given by

![Equation](https://latex.codecogs.com/gif.latex?f(P,D,A)=P\left(\frac{A(1-D)}{D&plus;A(1-D)}A&plus;D\right))

where ![Equation](https://latex.codecogs.com/gif.latex?P=\text{sphere&space;color},\&space;D=\text{direct&space;light},\&space;A=\text{ambient&space;light}&space;\in&space;[0,1]) and the computation is done pointwise.

I derived this model by myself so it's possible that it might be off (feedback welcome). 
