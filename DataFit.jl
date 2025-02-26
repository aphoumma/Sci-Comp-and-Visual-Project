module DataFit

import Base.show

using RecipesBase, ForwardDiff, LinearAlgebra

export Point2D, XYData, linearRegression, gradientDescentBB, bestFitLine, bestExponentialFit




"""
this struct makes a Point2D object with x and y as the field types 
"""

struct Point2D{T <: Real}
    x::T
    y::T
end

#method to write the the Point2D point in standard form
Base.show(io::IO, pt::Point2D) = print(io, string("(", pt.x,",", pt.y, ")"))

#this is to make x and y points of the Point2D object to be the same type if they are different
Point2D(x::Real, y::Real) = Point2D(promote(x,y)...)




"""
This struct makes vector of Point2D objects called XYData
"""

struct XYData
    #stores vector of Point2D objects
    vertices::Vector{Point2D{T}} where T <: Real
    
    #constructor to take vector of xpts and vector of ypts
    function XYData(xpts::Vector{T}, ypts::Vector{T}) where T <: Real 
        #throws errow if xpts and ypts are diff size 
        length(xpts) == length(ypts)  || throw(ArgumentError("The x and y vectors are not the same size"))
        new(map((x,y) -> Point2D(x,y), xpts, ypts))
    end 
    
    #constructor to take vector of tuples
    function XYData(tups::Vector{Tuple{T,T}}) where T <: Real
        new(map(pt -> Point2D(pt[1],pt[2]), tups))
    end 
    
    #Create a constructor that creates a new XYData object from two vectors of the same length but different types (like integers and floats).
    function XYData(xpts::Vector{T}, ypts::Vector{S}) where {T <: Real, S <:Real}
        
    #throws errow if xpts and ypts are diff size 
    length(xpts) == length(ypts)  || throw(ArgumentError("The x and y vectors are not the same size"))
    new(map((x,y) -> Point2D(x,y), xpts, ypts))
    end
    

     
end


"""
this base.show prints XYData more neatly 
"""
Base.show(io::IO, n::XYData) = print(io, string("[",join(n.vertices, ","),"]"))



"""
this function plots the XYdata points onto a scatter plot 
"""
@recipe function f(n::XYData)
    legend --> false
    title --> "XYData  Scatter Plot"
    seriestype --> :scatter
    
    xpts = map(pt->pt.x, n.vertices)
    ypts = map(pt->pt.y, n.vertices)
    
    
    push!(xpts, n.vertices[1].x)
    push!(ypts, n.vertices[1].y)
return 
    xpts, ypts
end




"""
this function approximates the slope (m) and intercept (b) of a best fit line for the given data in the form m,b
"""
function linearRegression(Data::XYData)
    xpts = map(pt->pt.x ,Data.vertices) 
    ypts = map(pt->pt.y ,Data.vertices) 
    m = (length(xpts)*sum(xpts.*ypts) - sum(xpts)*sum(ypts))/(length(ypts)*sum(xpts.^2)-sum(xpts)^2)
    b = (sum(ypts) - m*sum(xpts))/length(xpts)
    m,b
end



function gradientDescentBB(f::Function,x₀::Vector; max_steps = 100)
  local steps = 0
  local ∇f₀ = ForwardDiff.gradient(f,x₀)
  local x₁ = x₀ - 0.25 * ∇f₀ # need to start with a value for x₁
  while norm(∇f₀)> 1e-4 && steps < max_steps
    ∇f₁ = ForwardDiff.gradient(f,x₁)
    Δ∇f = ∇f₁-∇f₀
    x₂ = x₁ - abs(dot(x₁-x₀,Δ∇f))/norm(Δ∇f)^2*∇f₁
    x₀ = x₁
    x₁ = x₂
    ∇f₀ = ∇f₁
    steps += 1
  end
  @show steps
  steps < max_steps || throw(ErrorException("The number of steps has exceeded $max_steps"))
  x₁
end



function bestFitLine(data::XYData)
    function S(c)
        a=c[1] #a is slope 
        b=c[2] #b is y intercept 
        sum(pt->(a*pt.x+b-pt.y)^2,data.vertices)
    end
    gradientDescentBB(S,[1,2])
end


"""
Function to find best exponential fit. Takes in XYData object as argument
- uses IpopT and JuMP to find minimum
"""
function bestExponentialFit(data::XYData)

model = Model(Ipopt.Optimizer)
set_optimizer_attribute(model,"print_level",5) # this can be level 1 through 12.  1 minimal.
@variable(model, a, start = 0.0)
@variable(model, b, start = 0.0)
@variable(model, c, start = 0.0)

@NLobjective(model, Min, (1 - a)^2 + 100 * (b - a^2)^2)

optimize!(model)
@show value(a),value(b), value(c)
    
#gradientDescentBB(S,[1,2,3])
end   




end #end module SciCompProjectModule


#2. Write a function called bestFitLine that minimizes equation (1) for a given set of data using the Barzilai–Borwein gradient descent code in problem #1. The only input should be a XYData object and should return a named tuple or a new datatype. Add the function to your module.
#function bestFitLine(XYData::XYData)

#4. consider a function of the form f(x;a,b,c) = ae^(bx) + C. You can write a best fit function for this by minimizing:


#Write a function called bestFitExponential that uses either the gradient descent from #1 or the functions
#from the JuMP module to find the minimum of (3).

#5. Write a test for your bestFitExponential function that uses a set of data that is generated from an exponential function and it should fit (fairly close) the given function.

#6. Write a function similar to that in #4 to minimize a periodic function of the form
