-- UIVerticalSlider Class, represents a Frame that acts as a vertical slider
-- Bottom is lower bound
-- Enduo(Dynamese)
-- 6.30.2021



local Mouse
local UISlider = require(script.Parent.UISlider)
local UIVSlider = {}
UIVSlider.__index = UIVSlider
setmetatable(UIVSlider, UISlider)


-- UIVSlider constructor
-- @param instance <Frame>
-- @param container <UIContainer>
-- @param initialValue == 0.5, <Float> [0, 1]
-- @param lowerBound <float> == 0
-- @param upperBound <float> == 1
-- @return <UIVSlider>
function UIVSlider.new(instance, container, initialValue, lowerBound, upperBound)
    Mouse = Mouse or UIVSlider.LocalPlayer:GetMouse()

    -- superclass (UISlider) expects "UISlider" to exist
    --  it is currently "UIVSlider" to identify it as a vertical slider
    instance.UIVSlider.Name = "UISlider"

	local self = UISlider.new(instance, container, initialValue, lowerBound, upperBound)

	return setmetatable(self, UIVSlider)
end


-- @Override
-- @param slider <UIVSlider>
function UIVSlider:_SliderValue(slider)
    local height = slider.Instance.UISlider.AbsoluteSize.Y
    local top = slider.Instance.UISlider.AbsolutePosition.Y
    local mousePos = Mouse.Y

    -- invert ratio
    return slider._LowerBound + math.clamp(1 - (mousePos - top) / height, 0, 1) * slider._Length
end


return UIVSlider
