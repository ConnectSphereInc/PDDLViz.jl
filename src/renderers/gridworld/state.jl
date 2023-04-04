function render_state!(
    canvas::Canvas, renderer::GridworldRenderer,
    domain::Domain, state::Observable;
    options...
)
    # Update options
    options = merge(renderer.state_options, options)
    # Set canvas state observable (replacing any previous state)
    canvas.state = state
    # Extract or construct main axis
    ax = get(canvas.blocks, 1) do 
        _ax = Axis(canvas.layout[1,1], aspect=DataAspect())
        hidedecorations!(_ax, grid=false)
        push!(canvas.blocks, _ax)
        return _ax
    end
    # Get grid dimensions from PDDL state
    base_grid = @lift $state[renderer.grid_fluents[1]]
    height = @lift size($base_grid, 1)
    width = @lift size($base_grid, 2)
    # Render grid variables as heatmaps
    for (i, grid_fluent) in enumerate(renderer.grid_fluents)
        grid = @lift reverse(transpose(float($state[grid_fluent])), dims=2)
        cmap = cgrad([:transparent, renderer.grid_colors[i]])
        crange = @lift (min(minimum($grid), 0), max(maximum($grid), 1))
        heatmap!(ax, grid, colormap=cmap, colorrange=crange)
    end
    # Set ticks to show grid
    map!(w -> (1:w-1) .+ 0.5, ax.xticks, width)
    map!(h -> (1:h-1) .+ 0.5, ax.yticks, height) 
    ax.xgridcolor, ax.ygridcolor = :black, :black
    ax.xgridstyle, ax.ygridstyle = :dash, :dash
    # Render locations
    if get(options, :show_locations, true)
        for (x, y, label, color) in renderer.locations
            _y = @lift $height - y + 1
            fontsize = 1 / (1.5*length(label)^0.5)
            text!(ax, x, _y; text=label, color=color, align=(:center, :center),
                  markerspace=:data, fontsize=fontsize)
        end
    end
    # Render objects
    default_obj_renderer(d, s, o) = SquareShape(0, 0, 0.2, color=:gray)
    if get(options, :show_objects, true)
        # Render objects with type-specific graphics
        for type in renderer.obj_type_z_order
            for obj in PDDL.get_objects(domain, state[], type)
                r = get(renderer.obj_renderers, type, default_obj_renderer)
                graphic = @lift begin
                    x = $state[renderer.get_obj_x(obj)]
                    y = $height - $state[renderer.get_obj_y(obj)] + 1
                    translate(r(domain, $state, obj), x, y)
                end
                graphicplot!(ax, graphic)
           end
        end
        # Render remaining objects
        # for (obj, type) in PDDL.get_objtypes(state[])
        #     type in renderer.obj_type_z_order && continue
        #     graphic = @lift begin
        #         x = $state[renderer.get_obj_x(obj)]
        #         y = $height - $state[renderer.get_obj_y(obj)] + 1
        #         translate(default_obj_renderer(domain, $state, obj), x, y)
        #     end
        #     graphicplot!(ax, graphic)
        # end
    end
    # Render agent
    if get(options, :show_agent, true)
        graphic = @lift begin
            x = $state[renderer.get_agent_x()]
            y = $height - $state[renderer.get_agent_y()] + 1
            translate(renderer.agent_renderer(domain, $state), x, y)
        end
        graphicplot!(ax, graphic)
    end
    # Render inventories
    if renderer.show_inventory
        colsize!(canvas.layout, 1, Auto(1))
        rowsize!(canvas.layout, 1, Auto(1))
        for (i, inventory_fn) in enumerate(renderer.inventory_fns)
            # Extract objects
            ty = get(renderer.inventory_types, i, :object)
            sorted_objs = sort(PDDL.get_objects(domain, state[], ty), by=string)
            # Extract or construct axis for each inventory
            ax_i = get(canvas.blocks, i+1) do
                title = get(renderer.inventory_labels, i, "Inventory")
                _ax = Axis(canvas.layout[i+1, 1], aspect=DataAspect(),
                           title=title, titlealign=:left,
                           titlefont=:regular, titlesize=20)
                hidedecorations!(_ax, grid=false)
                push!(canvas.blocks, _ax)
                return _ax
            end
            # Render inventory as heatmap
            inventory_size = @lift max(length(sorted_objs), $width)
            cmap = cgrad([:transparent, :black])
            heatmap!(ax_i, @lift(zeros($inventory_size, 1)),
                     colormap=cmap, colorrange=(0, 1))
            map!(w -> (1:w-1) .+ 0.5, ax_i.xticks, inventory_size)
            map!(ax_i.limits, inventory_size) do w
                return ((0.5, w + 0.5), nothing)
            end
            ax_i.yticks = [0.5, 1.5]
            ax_i.xgridcolor, ax_i.ygridcolor = :black, :black
            ax_i.xgridstyle, ax_i.ygridstyle = :solid, :solid
            # Compute object locations
            obj_locs = @lift begin
                locs = Int[]
                n = 0
                for obj in sorted_objs
                    if inventory_fn(domain, $state, obj)
                        push!(locs, n += 1)
                    else
                        push!(locs, -1)
                    end
                end
                return locs
            end
            # Render objects in inventory
            for (j, obj) in enumerate(sorted_objs)
                type = PDDL.get_objtype(state[], obj)
                r = get(renderer.obj_renderers, type, default_obj_renderer)
                graphic = @lift begin
                    x = $obj_locs[j]
                    g = translate(r(domain, $state, obj), x, 1)
                    g.attributes[:visible] = x > 0
                    g
                end
                graphicplot!(ax_i, graphic)
            end
            # Resize row
            rowsize!(canvas.layout, i+1, Auto(1/inventory_size[]))
        end
        rowgap!(canvas.layout, 10)
        resize_to_layout!(canvas.figure)
    end
    # Return the canvas
    return canvas
end
