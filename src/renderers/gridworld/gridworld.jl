export GridworldRenderer

"""
    GridworldRenderer(; options...)

Customizable renderer for 2D gridworld domains.

# General options

$(TYPEDFIELDS)
"""
@kwdef mutable struct GridworldRenderer <: Renderer
    "Default figure resolution, in pixels."
    resolution::Tuple{Int, Int} = (800, 800)
    "PDDL fluents that represent the grid layers (walls, etc)."
    grid_fluents::Vector{Term} = [pddl"(walls)"]
    "Colors for each grid layer."
    grid_colors::Vector = [:black]
    "Whether the domain has an agent not associated with a PDDL object."
    has_agent::Bool = true
    "Function that returns the PDDL fluent for the agent's x position."
    get_agent_x::Function = () -> pddl"(xpos)"
    "Function that returns the PDDL fluent for the agent's y position."
    get_agent_y::Function = () -> pddl"(ypos)"
    "Takes an object constant and returns the PDDL fluent for its x position."
    get_obj_x::Function = obj -> Compound(:xloc, [obj])
    "Takes an object constant and returns the PDDL fluent for its y position."
    get_obj_y::Function = obj -> Compound(:yloc, [obj])
    "Agent renderer, of the form `(domain, state) -> Graphic`."
    agent_renderer::Function = (d, s) -> CircleShape(0, 0, 0.3, color=:black)
    "Per-type object renderers, of the form `(domain, state, obj) -> Graphic`."
    obj_renderers::Dict{Symbol, Function} = Dict{Symbol, Function}(
        :object => (d, s, o) -> SquareShape(0, 0, 0.2, color=:gray)
    )
    "Z-order for object types, from bottom to top."
    obj_type_z_order::Vector{Symbol} = collect(keys(obj_renderers))
    "List of `(x, y, label, color)` tuples to label locations on the grid."
    locations::Vector{Tuple} = Tuple[]
    "Whether to show an object inventory for each function in `inventory_fns`."
    show_inventory::Bool = false
    "Inventory indicator functions of the form `(domain, state, obj) -> Bool`."
    inventory_fns::Vector{Function} = Function[]
    "Types of objects that can be each inventory."
    inventory_types::Vector{Symbol} = Symbol[]
    "Axis titles / labels for each inventory."
    inventory_labels::Vector{String} = String[]
    "Inventory label font size."
    inventory_labelsize::Real = 20
    "Whether to show an object vision for each function in `vision_fns`."
    show_vision::Bool = false
    "Vision indicator functions of the form `(domain, state, obj) -> Bool`."
    vision_fns::Vector{Function} = Function[]
    "Types of objects that can be each vision."
    vision_types::Vector{Symbol} = Symbol[]
    "Vision labels for each vision indicator."
    vision_labels::Vector{String} = String[]
    "Vision label font size."
    vision_labelsize::Real = 20
    "Default options for state rendering."
    state_options::Dict{Symbol, Any} =
        default_state_options(GridworldRenderer)
    "Default options for trajectory rendering."
    trajectory_options::Dict{Symbol, Any} =
        default_trajectory_options(GridworldRenderer)
    "Default options for animation rendering."
    anim_options::Dict{Symbol, Any} =
        default_anim_options(GridworldRenderer)
end

function new_canvas(renderer::GridworldRenderer)
    figure = Figure()
    resize!(figure.scene, renderer.resolution)
    layout = GridLayout(figure[1,1])
    return Canvas(figure, layout)
end
new_canvas(renderer::GridworldRenderer, figure::Figure) =
    Canvas(figure, GridLayout(figure[1,1]))
new_canvas(renderer::GridworldRenderer, gridpos::GridPosition) =
    Canvas(Makie.get_top_parent(gridpos), GridLayout(gridpos))

function gw_agent_loc(
    renderer::GridworldRenderer, state::State,
    height = size(state[renderer.grid_fluents[1]], 1)
)
    x = state[renderer.get_agent_x()]
    y = height - state[renderer.get_agent_y()] + 1
    return (x, y)
end

function gw_obj_loc(
    renderer::GridworldRenderer, state::State, obj::Const,
    height = size(state[renderer.grid_fluents[1]], 1)
)
    x = state[renderer.get_obj_x(obj)]
    y = height - state[renderer.get_obj_y(obj)] + 1
    return (x, y)
end

# State and trajectory rendering / animation
include("state.jl")
include("trajectory.jl")
include("animate.jl")

include("utils.jl")

# Solution rendering
include("path_search.jl")
include("policy.jl")

# Animated solving / planning
include("anim_forward.jl")
include("anim_rtdp.jl")
include("anim_rths.jl")

# Add documentation for auxiliary options
Base.with_logger(Base.NullLogger()) do
    @doc """
    $(@doc GridworldRenderer)

    # State options

    These options can be passed as keyword arguments to [`render_state`](@ref):

    $(Base.doc(default_state_options, Tuple{Type{GridworldRenderer}}))

    # Trajectory options

    These options can be passed as keyword arguments to [`render_trajectory`](@ref):

    $(Base.doc(default_trajectory_options, Tuple{Type{GridworldRenderer}}))

    # Animation options

    These options can be passed as keyword arguments to animation functions:

    $(Base.doc(default_anim_options, Tuple{Type{GridworldRenderer}}))
    """
    GridworldRenderer
end
