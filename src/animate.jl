export anim_plan!, anim_trajectory!
export anim_plan, anim_trajectory

"""
    Animation

Displayable animation which wraps a `VideoStream` object. Can be displayed
with `show(io, MIME"text/html"(), anim)`, or saved with `save(path, anim)`.
"""
struct Animation
    videostream::VideoStream
end

Base.show(io::IO, ::MIME"juliavscode/html", anim::Animation) =
    show(io, MIME"text/html"(), anim.videostream)
Base.show(io::IO, m::MIME"text/html", anim::Animation) =
    show(io, m, anim.videostream)
FileIO.save(path::AbstractString, anim::Animation; kwargs...) =
    save(path, anim.videostream; kwargs...)

"""
    anim_plan([path], renderer, domain, state, actions;
              format="mp4", framerate=5, show=false, options...)
              
    anim_plan!([path], canvas, renderer, domain, state, actions;
               format="mp4", framerate=5, show=is_displayed(canvas), options...)

Uses `renderer` to animate a series of `actions` in a PDDL `domain` starting
from `state` (updating the `canvas` if one is provided). If a `path` is
specified, the animation is saved to that file, and the `path` is returned.
Otherwise, a [`Animation`](@ref) object is returned, which can be saved
or displayed. 
"""
function anim_plan(
    renderer::Renderer, domain::Domain, state::State, actions;
    show::Bool=false, kwargs...
)
    canvas = new_canvas(renderer)
    return anim_plan!(canvas, renderer, domain, state, actions;
                      show=show, kwargs...)
end

function anim_plan(path::AbstractString, args...; kwargs...)
    format = lstrip(splitext(path)[2], '.')
    save(path, anim_plan(args...; format=format, kwargs...))
end

function anim_plan!(
    canvas::Canvas, renderer::Renderer, domain::Domain, state::State, actions;
    format="mp4", framerate=5, show::Bool=is_displayed(canvas),
    showrate=framerate, options...
)
    if canvas.state === nothing
        render_state!(canvas, renderer, domain, state; options...)
    else
        canvas.state[] = state
    end
    if show && !is_displayed(canvas)
        display(canvas)
    end
    record_args = filter(Dict(options)) do (k, v)
        k in (:compression, :profile, :pixel_format)
    end
    vs = Record(canvas.figure; visible=is_displayed(canvas), format=format,
                framerate=framerate, record_args...) do io
        recordframe!(io)
        for act in actions
            canvas.state[] = PDDL.transition(domain, canvas.state[], act)
            recordframe!(io)
            if show
                notify(canvas.state)
                sleep(1/showrate)
            end
        end
    end
    return Animation(vs)
end

function anim_plan!(path::AbstractString, args...; kwargs...)
    format = lstrip(splitext(path)[2], '.')
    save(path, anim_plan!(args...; format=format, kwargs...))
end

@doc (@doc anim_plan) anim_plan!

"""
    anim_trajectory([path], renderer, domain, trajectory;
                    format="mp4", framerate=5, show=false, options...)
                    
    anim_trajectory!([path], canvas, renderer, domain, trajectory;
                     format="mp4", framerate=5, show=is_displayed(canvas),
                     options...)

Uses `renderer` to animate a `trajectory` in a PDDL `domain` (updating the
`canvas` if one is provided). If a `path` is specified, the animation is
saved to that file, and the `path` is returned. Otherwise, a [`Animation`](@ref)
object is returned, which can be saved or displayed.
"""
function anim_trajectory(
    renderer::Renderer, domain::Domain, trajectory;
    show::Bool=false, kwargs...
)
    canvas = new_canvas(renderer)
    return anim_trajectory!(canvas, renderer, domain, trajectory;
                            show=show, kwargs...)
end

function anim_trajectory(path::AbstractString, args...; kwargs...)
    format = lstrip(splitext(path)[2], '.')
    save(path, anim_trajectory(args...; format=format, kwargs...))
end

function anim_trajectory!(
    canvas::Canvas, renderer::Renderer, domain::Domain, trajectory;
    format="mp4", framerate=5, show::Bool=is_displayed(canvas),
    showrate=framerate, options...
)
    if canvas.state === nothing
        render_state!(canvas, renderer, domain, trajectory[1]; options...)
    else
        canvas.state[] = trajectory[1]
    end
    if show && !is_displayed(canvas)
        display(canvas)
    end
    record_args = filter(Dict(options)) do (k, v)
        k in (:compression, :profile, :pixel_format)
    end
    vs = Record(canvas.figure; visible=is_displayed(canvas), format=format,
                framerate=framerate, record_args...) do io
        recordframe!(io)
        for state in trajectory[2:end]
            canvas.state[] = state
            recordframe!(io)
            if show
                notify(canvas.state)
                sleep(1/showrate)
            end
        end
    end
    return Animation(vs)
end

function anim_trajectory!(path::AbstractString, args...; kwargs...)
    format = lstrip(splitext(path)[2], '.')
    save(path, anim_trajectory!(args...; format=format, kwargs...))
end

@doc (@doc anim_trajectory) anim_trajectory!