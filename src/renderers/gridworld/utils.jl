# Check if the location is a wall
function is_wall(walls, x, y)
    return walls[11 - y, x]
end

# Check if the location is within the grid
function is_valid_loc(x, y, width, height)
    if (x >= 1) && (x <= width[]) && (y >= 1) && (y <= height[])
        return true
    end
    return false
end


# Check if there is a wall between the agent and the target
# Bresenham's line algorithm
function is_path_blocked(agent_x, agent_y, target_x, target_y, walls)
    dx = abs(target_x - agent_x)
    dy = -abs(target_y - agent_y)
    sx = agent_x < target_x ? 1 : -1
    sy = agent_y < target_y ? 1 : -1
    err = dx + dy

    x, y = agent_x, agent_y

    # While the destination has not been reached
    while x != target_x || y != target_y

        e2 = 2 * err

        # Check diagonal walls
        if e2 >= dy && e2 <= dx
            if is_wall(walls, x + sx, y) && is_wall(walls, x, y + sy)
                return true
            end

            if abs(x - target_x) > abs(y - target_y)
                if is_wall(walls, x + sx, y)
                    return true
                end
            else
                if is_wall(walls, x, y + sy)
                    return true
                end
            end
        end

        # Update error and position
        if e2 >= dy
            if x == target_x
                break
            end
            err += dy
            x += sx
        end
        if e2 <= dx
            if y == target_y
                break
            end
            err += dx
            y += sy
        end

        # Check if the current position is a wall
        if is_wall(walls, x, y)
            return true
        end
    end

    return false
end

# Calculate the visible range as seen by the agent (offset from the agent's location)
function calculate_vision_offset(dx, dy, prev_offset)
    if dx > 0  # Moving right
        offset = [(0, 0), (1, 0), (2, 0), (1, 1), (2, 1), (2, 2), (1, -1), (2, -1), (2, -2)]
    elseif dx < 0  # Moving left
        offset = [(0, 0), (-1, 0), (-2, 0), (-1, 1), (-2, 1), (-2, 2), (-1, -1), (-2, -1), (-2, -2)]
    elseif dy > 0  # Moving up
        offset = [(0, 0), (0, 1), (0, 2), (1, 1), (1, 2), (2, 2), (-1, 1), (-1, 2), (-2, 2)]
    elseif dy < 0  # Moving down
        offset = [(0, 0), (0, -1), (0, -2), (1, -1), (1, -2), (2, -2), (-1, -1), (-1, -2), (-2, -2)]
    else    # Not moving
        offset = prev_offset
    end
    return offset
end