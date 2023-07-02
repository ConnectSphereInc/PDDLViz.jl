function render_sol!(
    canvas::Canvas, renderer::GridworldRenderer, domain::Domain,
    state::Observable, sol::Observable{<:PathSearchSolution};
    options...
)
    # Render initial state if not already on canvas
    if canvas.state === nothing
        render_state!(canvas, renderer, domain, state; options...)
    end
    # Extract main axis
    ax = canvas.blocks[1]
    # Update options
    options = merge(renderer.trajectory_options, options)
    # Render search tree
    if get(options, :show_search, true) && !isnothing(sol[].search_tree)
        # Set up observables for agent
        agent_locs = Observable(Point2f[])
        agent_dirs = Observable(Point2f[])
        # Set up observables for tracked objects
        objects = get(options, :tracked_objects, Const[])
        types = get(options, :tracked_types, Symbol[])
        for ty in types
            objs = PDDL.get_objects(domain, state, ty)
            append!(objects, objs)
        end
        obj_locs = [Observable(Point2f[]) for _ in 1:length(objects)]
        obj_dirs = [Observable(Point2f[]) for _ in 1:length(objects)]
        # Fill observables
        on(sol; update = true) do sol
            # Clear previous values
            if renderer.has_agent
                empty!(agent_locs[]); empty!(agent_dirs[])
            end
            for (ls, ds) in zip(obj_locs, obj_dirs)
                empty!(ls[]); empty!(ds[])
            end
            # Determine node iteration order
            has_order = !isempty(sol.search_order)
            node_ids = has_order ? sol.search_order : keys(sol.search_tree)
            if has_order
                push!(node_ids, hash(sol.trajectory[end]))
            end
            # Iterate over nodes in search tree (in order if available)
            for id in node_ids
                node = sol.search_tree[id]
                isnothing(node.parent_id) && continue
                state = node.state
                prev_state = sol.search_tree[node.parent_id].state
                height = size(node.state[renderer.grid_fluents[1]], 1)
                # Update agent observables
                if renderer.has_agent
                    x = state[renderer.get_agent_x()]
                    y = height - state[renderer.get_agent_y()] + 1
                    prev_x = prev_state[renderer.get_agent_x()]
                    prev_y = height - prev_state[renderer.get_agent_y()] + 1
                    push!(agent_locs[], Point2f(prev_x, prev_y))
                    push!(agent_dirs[], Point2f(x-prev_x, y-prev_y))
                end
                # Update object observables
                for (i, obj) in enumerate(objects)
                    x = state[renderer.get_obj_x(obj)]
                    y = height - state[renderer.get_obj_y(obj)] + 1
                    prev_x = prev_state[renderer.get_obj_x(obj)]
                    prev_y = height - prev_state[renderer.get_obj_y(obj)] + 1
                    push!(obj_locs[i][], Point2f(prev_x, prev_y))
                    push!(obj_dirs[i][], Point2f(x-prev_x, y-prev_y))
                end
            end
            # Trigger updates
            if renderer.has_agent
                notify(agent_locs); notify(agent_dirs)
            end
            for (ls, ds) in zip(obj_locs, obj_dirs)
                notify(ls); notify(ds)
            end
        end
        # Create arrow plots for agent and tracked objects
        node_marker = get(options, :search_marker, '⦿') 
        node_size = get(options, :search_size, 0.3)
        edge_arrow = get(options, :search_arrow, '▷')  
        colors = @lift isempty($sol.search_order) ?
            get(options, :search_color, :red) : 1:length($agent_locs)
        cmap = get(options, :search_colormap, cgrad([:blue, :red]))
        arrows!(ax, agent_locs, agent_dirs; colormap=cmap, color=colors,
                arrowsize=node_size, arrowhead=node_marker, markerspace=:data)
        edge_locs = @lift $agent_locs .+ ($agent_dirs .* 0.5)
        edge_rotations = @lift [atan(d[2], d[1]) for d in $agent_dirs]
        edge_markers = @lift Char[d == Point2f(0, 0) ? node_marker : edge_arrow
                                  for d in $agent_dirs]
        scatter!(ax, edge_locs, marker=edge_markers, rotation=edge_rotations,
                 markersize=node_size, markerspace=:data, 
                 colormap=cmap, color=colors)
        for (ls, ds) in zip(obj_locs, obj_dirs)
            colors = @lift isempty($sol.search_order) ?
                get(options, :search_color, :red) : 1:length($ls)
            arrows!(ax, ls, ds; colormap=cmap, color=colors, markerspace=:data,
                    arrowsize=node_size, arrowhead=node_marker)
            e_ls = @lift $ls .+ ($ds .* 0.5)
            e_rs = @lift [atan(d[2], d[1]) for d in $ds]
            e_ms = @lift Char[d == Point2f(0, 0) ? node_marker : edge_arrow 
                              for d in $ds]
            scatter!(ax, e_ls, marker=e_ms, rotation=e_rs, markersize=node_size,
                     markerspace=:data, colormap=cmap, color=colors)
        end
    end
    # Render trajectory
    if get(options, :show_trajectory, true) && !isnothing(sol[].trajectory)
        trajectory = @lift($sol.trajectory)
        render_trajectory!(canvas, renderer, domain, trajectory; options...)
    end
    return canvas
end
