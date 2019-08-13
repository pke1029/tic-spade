# Spade
A tool for generating realistic pixelated sphere.

![](demo.gif)

Check it out here: https://tic.computer/play?cart=919

# Model

The model is given by

![Equation](https://latex.codecogs.com/gif.latex?f(P,D,A)=P\left(\frac{A(1-D)}{D&plus;A(1-D)}A&plus;D\right))

where P is the color of the sphere, D is the direct light, and A is the ambient light. All computation is done pointwise.

I derived this model by myself so it's possible that it might be off (feedback welcome). 
