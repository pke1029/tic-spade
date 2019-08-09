# Spade
A tool for generating realistic pixelated sphere.

![](demo.gif)

# Model

The model I'm using is given by

![Equation](https://latex.codecogs.com/gif.latex?f(P,D,A)=P\left(\frac{A(1-D)}{D&plus;A(1-D)}A&plus;D\right))

where P is the color of the sphere, D is the direct light, and A is the ambient light. All computation is done pointwise.

I derived this model by myself so it's possible that it might be off (feedback welcome). 
