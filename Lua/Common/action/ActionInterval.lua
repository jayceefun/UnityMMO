cc = cc or {}

cc.ExtraAction = cc.ExtraAction or BaseClass(cc.FiniteTimeAction)
function cc.ExtraAction:__init()
    
end
function cc.ExtraAction:clone()
    return cc.ExtraAction.New()
end

function cc.ExtraAction:reverse()
    return cc.ExtraAction.New()
end

function cc.ExtraAction:update(time)
end

function cc.ExtraAction:step(dt)
end


cc.ActionInterval = cc.ActionInterval or BaseClass(cc.FiniteTimeAction)

cc.ActionInterval.FLT_EPSILON = 1.192092896e-07

function cc.ActionInterval:__init()
    self._classType = "ActionInterval"
end

function cc.ActionInterval:getElapsed()
    return self._elapsed
end

function cc.ActionInterval:setAmplitudeRate(amp)
    --Subclass should implement this method!
end

function cc.ActionInterval:getAmplitudeRate()
    --Subclass should implement this method!
    return 0
end

function cc.ActionInterval:isDone()
    return self._elapsed >= self._duration
end

function cc.ActionInterval:sendUpdateEventToScript(dt, actionObject)
    return false;
end

function cc.ActionInterval:step(dt)
    if self._firstTick then
    	self._firstTick = false
        self._elapsed = 0
    else
        self._elapsed = self._elapsed + dt
    end
    local updateDt = math.max(0,math.min(1,self._elapsed / math.max(self._duration,cc.ActionInterval.FLT_EPSILON)))

    self:update(updateDt)
end

function cc.ActionInterval:startWithTarget(target)
    cc.FiniteTimeAction.startWithTarget(self, target);
    self._elapsed = 0
    self._firstTick = true
end

function cc.ActionInterval:reverse()
	print("Cat_Error:ActionInterval.lua [ActionInterval:reverse] should not exec this method!")
    return nil
end

function cc.ActionInterval:clone()
    print("Cat_Error:ActionInterval.lua [ActionInterval:clone] should not exec this method!")
    return nil
end

function cc.ActionInterval:initWithDuration(d)
    self._duration = d
    if self._duration == 0 then
        self._duration = cc.ActionInterval.FLT_EPSILON
    end

    self._elapsed = 0
    self._firstTick = true

    return true
end

--MoveBy start
cc.MoveBy = cc.MoveBy or BaseClass(cc.ActionInterval)

function cc.MoveBy:__init(duration, delta_x, delta_y, delta_z)
    self:initWithDuration(duration, delta_x, delta_y, delta_z)
end

function cc.MoveBy:clone()
    return cc.MoveBy.New(self._duration, self._positionDeltaX, self._positionDeltaY, self._positionDeltaZ)
end

function cc.MoveBy:reverse()
    return cc.MoveBy.New(self._duration, self._positionDeltaX and -self._positionDeltaX, self._positionDeltaY and -self._positionDeltaY, self._positionDeltaZ and -self._positionDeltaZ)
end

function cc.MoveBy:startWithTarget(target)
    cc.ActionInterval.startWithTarget(self, target)
    self._previousPositionX, self._previousPositionY, self._previousPositionZ = cc.Wrapper.GetLocalPosition(target)
    self._startPositionX, self._startPositionY, self._startPositionZ = self._previousPositionX, self._previousPositionY, self._previousPositionZ
end

function cc.MoveBy:update(t)
   if self._target then
        local currentPosX, currentPosY, currentPosZ = cc.Wrapper.GetLocalPosition(self._target)
        if self._positionDeltaX and self._positionDeltaX ~= 0 then
            self._previousPositionX = self._startPositionX + (self._positionDeltaX * t)
        end
        if self._positionDeltaY and self._positionDeltaY ~= 0 then
            self._previousPositionY = self._startPositionY + (self._positionDeltaY * t)
        end
        if self._positionDeltaZ and self._positionDeltaZ ~= 0 then
            self._previousPositionZ = self._startPositionZ + (self._positionDeltaZ * t)
        end
        cc.Wrapper.SetLocalPosition(self._target, self._previousPositionX, self._previousPositionY, self._previousPositionZ)
    end 
end

function cc.MoveBy:initWithDuration(duration, delta_x, delta_y, delta_z)
    cc.ActionInterval.initWithDuration(self, duration)
    self._positionDeltaX = delta_x
    self._positionDeltaY = delta_y
    self._positionDeltaZ = delta_z
end

--MoveBy end

--MoveTo start
cc.MoveTo = cc.MoveTo or BaseClass(cc.MoveBy)
function cc.MoveTo:__init(duration, x, y, z)
    self:initWithPos(duration, x, y, z)
end

function cc.MoveTo.create(duration, x, y, z)
    self:initWithPos(duration, x, y, z)
end

function cc.MoveTo:initWithPos(duration, x, y, z)
    cc.ActionInterval.initWithDuration(self, duration)
    self._endPositionX = x
    self._endPositionY = y
    self._endPositionZ = z
end

function cc.MoveTo:clone()
    return cc.MoveTo.New(self._duration, self._endPositionX, self._endPositionY, self._endPositionZ)
end

function cc.MoveTo:startWithTarget(target)
    cc.MoveBy.startWithTarget(self, target)
    local oldX, oldY, oldZ = cc.Wrapper.GetLocalPosition(target)
    self._positionDeltaX = self._endPositionX - oldX
    self._positionDeltaY = self._endPositionY - oldY
    self._positionDeltaZ = self._endPositionZ - oldZ
end

function cc.MoveTo:reverse()
    print("reverse() not supported in MoveTo")
    return nil
end
--MoveTo end

--Sequence start
cc.Sequence = cc.Sequence or BaseClass(cc.ActionInterval)

function cc.Sequence:__init()
end

function cc.Sequence.create( ... )
    local action = cc.Sequence.New()
    action._actions = {}
    action:initWithTable({...})
    return action
end

function cc.Sequence.createWithTable( action_tb )
    local action = cc.Spawn.New()
    action._actions = {}
    action:initWithTable(action_tb)
    return action
end

function cc.Sequence.createWithTwoActions(actionOne, actionTwo)
    local sequence = cc.Sequence.New()
    sequence:initWithTwoActions(actionOne, actionTwo);
    return sequence;
end

function cc.Sequence:initWithTable(actions)
    local count = #actions
    if (count == 0) then
        --进入这里也是正常的
        return
    end

    if (count == 1) then
        return self:initWithTwoActions(actions[1], cc.ExtraAction.New());
    end

    local prev = actions[1]
    for i=2,#actions-1 do
        prev = cc.Sequence.createWithTwoActions(prev, actions[i])
    end
   
    self:initWithTwoActions(prev, actions[count]);
end

function cc.Sequence:initWithTwoActions(actionOne, actionTwo)
    local d = actionOne:getDuration() + actionTwo:getDuration()
    cc.ActionInterval.initWithDuration(self, d)
    self._actions[0] = actionOne
    self._actions[1] = actionTwo
    return true
end

function cc.Sequence:clone()
    local a = cc.Sequence.New()
    a:initWithTwoActions(self._actions[0]:clone(), self._actions[1]:clone() )
    return a
end

function cc.Sequence:startWithTarget(target)
    cc.ActionInterval.startWithTarget(self, target)
    self._split = self._actions[0]:getDuration() / self._duration
    self._last = -1
end

function cc.Sequence:stop()
    -- Issue #1305
    if ( self._last ~= - 1) then
        self._actions[self._last]:stop()
    end

    cc.ActionInterval.stop(self)
end

function cc.Sequence:update(t)
    local found = 0
    local new_t = 0.0

    if( t < self._split ) then
        found = 0
        if( self._split ~= 0 ) then
            new_t = t / self._split
        else
            new_t = 1
        end
     else 
        found = 1;
        if ( self._split == 1 ) then
            new_t = 1;
        else
            new_t = (t-self._split) / (1 - self._split );
        end
    end

    if ( found==1 ) then
        if( self._last == -1 ) then
            -- action[0] was skipped, execute it.
            self._actions[0]:startWithTarget(self._target);
                self._actions[0]:update(1.0)
            self._actions[0]:stop()
        elseif( self._last == 0 ) then
            -- switching to action 1. stop action 0.
                self._actions[0]:update(1.0)
            self._actions[0]:stop()
        end
    elseif (found==0 and self._last==1 ) then
            self._actions[1]:update(0);
        self._actions[1]:stop();
    end
    -- Last action found and it is done.
    if( found == self._last and self._actions[found]:isDone() ) then
        return
    end

    -- Last action found and it is done
    if( found ~= self._last ) then
        self._actions[found]:startWithTarget(self._target);
    end
    self._actions[found]:update(new_t);
    self._last = found;
end

function cc.Sequence:reverse()
    return cc.Sequence.createWithTwoActions(self._actions[1]:reverse(), self._actions[0]:reverse())
end

--Sequence end

--ScaleTo start

cc.ScaleTo = cc.ScaleTo or BaseClass(cc.ActionInterval)

function cc.ScaleTo:__init(duration, sx, sy, sz)
    self:initWithDuration(duration, sx, sy, sz);
end

function cc.ScaleTo:initWithDuration(duration, sx, sy, sz)
    cc.ActionInterval.initWithDuration(self, duration)
    self._endScaleX = sx
    self._endScaleY = sy
    self._endScaleZ = sz
end

function cc.ScaleTo:clone()
    return ScaleTo.New(self._duration, self._endScaleX, self._endScaleY, self._endScaleZ)
end

function cc.ScaleTo:reverse()
    print("reverse() not supported in ScaleTo")
    return nil
end

function cc.ScaleTo:startWithTarget(target)
    cc.ActionInterval.startWithTarget(self, target);
    self._startScaleX, self._startScaleY, self._startScaleZ = cc.Wrapper.GetLocalScale(target)
    self._deltaX = self._endScaleX - self._startScaleX;
    self._deltaY = self._endScaleY - self._startScaleY;
    self._deltaZ = self._endScaleZ - self._startScaleZ;
end

function cc.ScaleTo:update(time)
    if self._target then
        cc.Wrapper.SetLocalScale(self._target, self._startScaleX + self._deltaX * time, self._startScaleY + self._deltaY * time, self._startScaleZ + self._deltaZ * time)
    end
end

--ScaleTo end

--Fade start
cc.FadeTo = cc.FadeTo or BaseClass(cc.ActionInterval)

function cc.FadeTo:__init(duration, opacity)
    self:initWithDuration(duration, opacity)
end

function cc.FadeTo:initWithDuration(duration, opacity)
    cc.ActionInterval.initWithDuration(self, duration)
    self._toOpacity = opacity;
end

function cc.FadeTo:clone()
    return FadeTo.New(self._duration, self._toOpacity)
end

function cc.FadeTo:reverse()
    print("reverse() not supported in FadeTo");
    return nil;
end

function cc.FadeTo:startWithTarget(target)
    cc.ActionInterval.startWithTarget(self, target);
    self._fromOpacity = cc.Wrapper.GetAlpha(target)
end

function cc.FadeTo:update(time)
    if self._target then
        local newOpacity = (self._fromOpacity + (self._toOpacity - self._fromOpacity) * time)
        cc.Wrapper.SetAlpha(self._target, newOpacity)
    end
end

cc.FadeIn = cc.FadeIn or BaseClass(cc.FadeTo)

function cc.FadeIn:__init(d)
    self:initWithDuration(d,1.0);
end

function cc.FadeIn:clone()
    return cc.FadeIn.New(self._duration)
end

function cc.FadeIn:reverse()
    return cc.FadeOut.New(self._duration)
end

function cc.FadeIn:startWithTarget(target)
    cc.ActionInterval.startWithTarget(self, target)
    
    self._toOpacity = 1.0
    
    self._fromOpacity = cc.Wrapper.GetAlpha(target)
end

cc.FadeOut = cc.FadeOut or BaseClass(cc.FadeTo)

function cc.FadeOut:__init(d)
    self:initWithDuration(d,0.0)
end

function cc.FadeOut:clone()
    return cc.FadeOut.New(self._duration,0.0);
end

function cc.FadeOut:startWithTarget(target)
    cc.ActionInterval.startWithTarget(self, target);
    
    self._toOpacity = 0.0
    
    self._fromOpacity = cc.Wrapper.GetAlpha(target)
end

function cc.FadeOut:reverse()
    return cc.FadeIn.New(self._duration)
end

--Fade end

--Rotate start
--Cat_Todo : 还没好，先别用
-- cc.RotateTo = cc.RotateTo or BaseClass(cc.ActionInterval)

-- function cc.RotateTo:__init(duration, dstAngle)
--     self._dstAngle = 0
--     self._startAngle = 0
--     self._diffAngle = 0
--     self:initWithDuration(duration, dstAngle)
-- end

-- function cc.RotateTo:initWithDuration(duration, dstAngle)
--     cc.ActionInterval.initWithDuration(self, duration)
--     self._dstAngle = dstAngle
-- end

-- function cc.RotateTo:clone()
--     return cc.RotateTo.New(self._duration, self._dstAngle)
-- end

-- function cc.RotateTo:calculateAngles(startAngle, diffAngle, dstAngle)
--     if (startAngle > 0) then
--         startAngle = math.fmod(startAngle, 360.0)
--     else
--         startAngle = math.fmod(startAngle, -360.0)
--     end

--     diffAngle = dstAngle - startAngle
--     if (diffAngle > 180) then
--         diffAngle = diffAngle - 360
--     end
--     if (diffAngle < -180) then
--         diffAngle = diffAngle + 360
--     end
--     return startAngle, diffAngle
-- end

-- function cc.RotateTo:startWithTarget(target)
--     cc.ActionInterval.startWithTarget(self, target)
    
--     self._startAngle = cc.Wrapper.GetLocalRotation(target)

--     self._startAngle, self._diffAngle = self:calculateAngles(self._startAngle, self._diffAngle, self._dstAngle)
-- end

-- function cc.RotateTo:update(time)
--     if (self._target) then
--         local newRotation = self._startAngle + self._diffAngle * time
--         self._target:SetFloat(ImageBoxProperty.Rotation, newRotation)
--     end
-- end

-- function cc.RotateTo:reverse()
--     print("RotateTo doesn't support the 'reverse' method")
--     return nil
-- end

-- cc.RotateBy = cc.RotateBy or BaseClass(cc.ActionInterval)

-- function cc.RotateBy:__init(duration, deltaAngle)
--     self._deltaAngle = 0
--     self._startAngle = 0
--     self:initWithDuration(duration, deltaAngle)
-- end

-- function cc.RotateBy:initWithDuration(duration, deltaAngle)
--     cc.ActionInterval.initWithDuration(self, duration)
--     self._deltaAngle = deltaAngle
-- end

-- function cc.RotateBy:clone()
--     return cc.RotateBy.New(self._duration, self._deltaAngle)
-- end

-- function cc.RotateBy:startWithTarget(target)
--     cc.ActionInterval.startWithTarget(self, target)
    
--     self._startAngle = self._target:GetFloat(ImageBoxProperty.Rotation)
-- end

-- function cc.RotateBy:update(time)
--     if (self._target) then
--         local newRotation = self._startAngle + self._deltaAngle * time
--         self._target:SetFloat(ImageBoxProperty.Rotation, newRotation)
--     end
-- end

-- function cc.RotateBy:reverse()
--     return cc.RotateBy.New(self._duration, -self._deltaAngle)
-- end
--Rotate end

--Repeat start
cc.Repeat = cc.Repeat or BaseClass(cc.ActionInterval)

function cc.Repeat:__init(action, times)
    self:initWithAction(action, times)
end

function cc.Repeat:initWithAction(action, times)
    local d = action:getDuration() * times
    cc.ActionInterval.initWithDuration(self, d)
        self._times = times;
        self._innerAction = action;

        self._actionInstant = action._classType and action._classType == "ActionInstant" or false
       
        self._total = 0;
end

function cc.Repeat:clone()
    -- no copy constructor
    return cc.Repeat.New(self._innerAction:clone(), self._times)
end

function cc.Repeat:startWithTarget(target)
    self._total = 0
    self._nextDt = self._innerAction:getDuration()/self._duration
    cc.ActionInterval.startWithTarget(self, target)
    self._innerAction:startWithTarget(target)
end

function cc.Repeat:stop()
    self._innerAction:stop()
    cc.ActionInterval.stop(self)
end

-- issue #80. Instead of hooking step:, hook update: since it can be called by any 
-- container action like Repeat, Sequence, Ease, etc..
function cc.Repeat:update(dt)
    if (dt >= self._nextDt) then
        while (dt >= self._nextDt and self._total < self._times) do
                self._innerAction:update(1.0)
            self._total = self._total + 1

            self._innerAction:stop();
            self._innerAction:startWithTarget(self._target)
            self._nextDt = self._innerAction:getDuration()/self._duration * (self._total+1)
        end

        -- fix for issue #1288, incorrect end value of repeat
        if(math.abs(dt - 1.0) < cc.ActionInterval.FLT_EPSILON and self._total < self._times) then
            self._innerAction:update(1.0);
            self._total = self._total + 1
        end

        -- don't set an instant action back or update it, it has no use because it has no duration
        if (not self._actionInstant) then
            if (self._total == self._times) then
                -- minggo: inner action update is invoked above, don't have to invoke it here
                   -- self._innerAction:update(1);
                self._innerAction:stop()
            else
                -- issue #390 prevent jerk, use right update
                self._innerAction:update(dt - (self._nextDt - self._innerAction:getDuration()/self._duration))
            end
        end
    else
        self._innerAction:update(math.fmod(dt * self._times,1.0))
    end
end

function cc.Repeat:isDone()
    return self._total == self._times
end

function cc.Repeat:reverse()
    return cc.Repeat.New(self._innerAction:reverse(), self._times)
end

cc.RepeatForever = cc.RepeatForever or BaseClass(cc.ActionInterval)

function cc.RepeatForever:__init(action)
    self:initWithAction(action)
end

function cc.RepeatForever:initWithAction(action)
    self._innerAction = action
end

function cc.RepeatForever:clone()
    return cc.RepeatForever.New(self._innerAction:clone())
end

function cc.RepeatForever:startWithTarget(target)
    cc.ActionInterval.startWithTarget(self, target)
    self._innerAction:startWithTarget(target)
end

function cc.RepeatForever:step(dt)
    self._innerAction:step(dt);
    if (self._innerAction:isDone()) then
        local diff = self._innerAction:getElapsed() - self._innerAction:getDuration()
        if (diff > self._innerAction:getDuration()) then
            diff = math.fmod(diff, self._innerAction:getDuration())
        end
        self._innerAction:startWithTarget(self._target)
        -- to prevent jerk. issue #390, 1247
        self._innerAction:step(0.0);
        self._innerAction:step(diff);
    end
end

function cc.RepeatForever:isDone()
    return false
end

function cc.RepeatForever:reverse()
    return cc.RepeatForever.New(self._innerAction:reverse())
end
--Repeat end

--Spawn start
cc.Spawn = cc.Spawn or BaseClass(cc.ActionInterval)

function cc.Spawn:__init()
end

function cc.Spawn.create( ... )
    local action = cc.Spawn.New()
    action._actions = {}
    action:initWithTable({...})
    return action
end

function cc.Spawn.createWithTable( action_tb )
    local action = cc.Spawn.New()
    action._actions = {}
    action:initWithTable(action_tb)
    return action
end

function cc.Spawn.createWithTwoActions(actionOne, actionTwo)
    local Spawn = cc.Spawn.New()
    Spawn:initWithTwoActions(actionOne, actionTwo);
    return Spawn
end

function cc.Spawn:initWithTable(actions)
    local count = #actions
    if (count == 0) then
        --进入这里也是正常的
        return
    end

    if (count == 1) then
        return initWithTwoActions(actions[1], cc.ExtraAction.New());
    end

    local prev = actions[1]
    for i=2,#actions-1 do
        prev = cc.Spawn.createWithTwoActions(prev, actions[i])
    end
   
    self:initWithTwoActions(prev, actions[count]);
end

function cc.Spawn:initWithTwoActions(actionOne, actionTwo)
    local d1 = actionOne:getDuration()
    local d2 = actionTwo:getDuration()
    local d = math.max(d1 , d2)
    cc.ActionInterval.initWithDuration(self, d)
    self._one = actionOne
    self._two = actionTwo
    if (d1 > d2) then
        self._two = cc.Sequence.New(actionTwo, cc.DelayTime.New(d1 - d2));
    elseif (d1 < d2) then
        self._one = cc.Sequence.New(actionOne, cc.DelayTime.New(d2 - d1));
    end
end

function cc.Spawn:clone()
    local a = cc.Spawn.New()
    a:initWithTwoActions(self._one:clone(), self._two:clone() )
    return a
end

function cc.Spawn:startWithTarget(target)
    cc.ActionInterval.startWithTarget(self, target)
    self._one:startWithTarget(target)
    self._two:startWithTarget(target)
end

function cc.Spawn:stop()
    self._one:stop()
    self._two:stop()
    cc.ActionInterval.stop(self)
end

function cc.Spawn:update(time)
    if (self._one) then
        self._one:update(time)
    end
    if (self._two) then
        self._two:update(time)
    end
end

function cc.Spawn:reverse()
    return cc.Spawn.New(self._one:reverse(), self._two:reverse())
end
--Spawn end

--DelayTime start

cc.DelayTime = cc.DelayTime or BaseClass(cc.ActionInterval)

function cc.DelayTime:__init(d)
    self:initWithDuration(d);
end

function cc.DelayTime:clone()
    return cc.DelayTime.New(self._duration)
end

function cc.DelayTime:update(time)
    --什么都不干
end

function cc.DelayTime:reverse()
    return cc.DelayTime.New(self._duration)
end

--DelayTime end
--SizeBy start
cc.SizeBy = cc.SizeBy or BaseClass(cc.ActionInterval)

function cc.SizeBy:__init(duration, delta_w, delta_h)
    self:initWithDuration(duration, delta_w, delta_h)
end

function cc.SizeBy:clone()
    return cc.SizeBy.New(self._duration, self._SizeDeltaW, self._SizeDeltaH)
end

function cc.SizeBy:reverse()
    return cc.SizeBy.New(self._duration, -self._SizeDeltaW, -self._SizeDeltaH)
end

function cc.SizeBy:startWithTarget(target)
    cc.ActionInterval.startWithTarget(self, target)

    self._previousSizeWidht,self._previousSizeHeight = cc.Wrapper.GetSize(target)
    self._startSizeX,self._startSizeY = self._previousSizeWidht,self._previousSizeHeight
end

function cc.SizeBy:update(t)
   if self._target then
        local currentW,currentH = cc.Wrapper.GetSize(self._target)
        local diffX = currentW - self._previousSizeWidht
        local diffY = currentH - self._previousSizeHeight
        local newSizeW = self._startSizeX + (self._SizeDeltaW * t)
        local newSizeH = self._startSizeY + (self._SizeDeltaH * t)
        -- self._target:SetVectorValue(WidgetProperty.Size,newSizeW,newSizeH)
        cc.Wrapper.SetSize(self._target, newSizeW, newSizeH)
        self._previousSizeWidht = newSizeW
        self._previousSizeHeight = newSizeH
   end 
end

function cc.SizeBy:initWithDuration(duration, delta_w, delta_h)
    cc.ActionInterval.initWithDuration(self,duration)
    self._SizeDeltaW = delta_w
    self._SizeDeltaH = delta_h
end

--SizeBy end

--SizeTo start
cc.SizeTo = cc.SizeTo or BaseClass(cc.SizeBy)
function cc.SizeTo:__init(duration, w, h)
    self:initWithSize(duration, w, h)
end

function cc.SizeTo:initWithSize(duration, w, h)
    cc.ActionInterval.initWithDuration(self, duration)
    self._endSizeW = w
    self._endSizeH = h
end

function cc.SizeTo:clone()
    return cc.SizeTo.New(self._duration, self._endSizeW, self._endSizeH)
end

function cc.SizeTo:startWithTarget(target)
    cc.SizeBy.startWithTarget(self, target)
    local oldW,oldH = cc.Wrapper.GetSize(target)
    self._SizeDeltaW = self._endSizeW - oldW
    self._SizeDeltaH = self._endSizeH - oldH
end

function cc.SizeTo:reverse()
    print("reverse() not supported in SizeTo")
    return nil
end
--SizeTo end


-- Bezier cubic formula:
--    ((1 - t) + t)3 = 1 
-- Expands to ...
--   (1 - t)3 + 3t(1-t)2 + 3t2(1 - t) + t3 = 1 
function cc.bezierat( a, b, c, d, t )
    return (math.pow(1-t,3) * a + 
            3*t*(math.pow(1-t,2))*b + 
            3*math.pow(t,2)*(1-t)*c +
            math.pow(t,3)*d )
end

-- BezierBy start
cc.BezierBy = cc.BezierBy or BaseClass(cc.ActionInterval)

--t为动作时间，c为控制点信息，比如 {end_pos={x=0,y=0},control_1={x=1,y=1},control_2={x=2,y=2}}
function cc.BezierBy:__init(t, c)
    self:initWithDuration(t, c)
end

function cc.BezierBy:initWithDuration(t, c)
    cc.ActionInterval.initWithDuration(self, t)
    self._config = c
end

function cc.BezierBy:startWithTarget(target)
    cc.ActionInterval.startWithTarget(self, target)
    local x, y = cc.Wrapper.GetLocalPosition(target)
    self._startPosition = {x=x, y = y}
    self._previousPosition = {x=x, y = y}
end

function cc.BezierBy:clone()
    return cc.BezierBy.New(self._duration, self._config)
end

function cc.BezierBy:update(time)
    if (self._target) then
        local xa = 0;
        local xb = self._config.control_1.x;
        local xc = self._config.control_2.x;
        local xd = self._config.end_pos.x;

        local ya = 0;
        local yb = self._config.control_1.y;
        local yc = self._config.control_2.y;
        local yd = self._config.end_pos.y;

        local x = cc.bezierat(xa, xb, xc, xd, time);
        local y = cc.bezierat(ya, yb, yc, yd, time);

-- #if CC_ENABLE_STACKABLE_ACTIONS
--         Vec2 currentPos = _target->getPosition();
--         Vec2 diff = currentPos - _previousPosition;
--         _startPosition = _startPosition + diff;

--         Vec2 newPos = _startPosition + Vec2(x,y);
--         _target->setPosition(newPos);

--         _previousPosition = newPos;
-- #else
        cc.Wrapper.SetLocalPosition(self._target, self._startPosition.x+x, self._startPosition.y+y)
-- #endif // !CC_ENABLE_STACKABLE_ACTIONS
    end
end

function cc.BezierBy:reverse()
    local r = {}
    r.end_pos = {x=-self._config.end_pos.x, y=-self._config.end_pos.y}
    r.control_1 = {x=0, y=0}
    r.control_1.x = self._config.control_2.x - self._config.end_pos.x
    r.control_1.y = self._config.control_2.y - self._config.end_pos.y
   
    r.control_2 = {x=0, y=0}
    r.control_2.x = self._config.control_1.x - self._config.end_pos.x
    r.control_2.y = self._config.control_1.y - self._config.end_pos.y

    return cc.BezierBy.New(self._duration, r)
end

-- BezierTo start
cc.BezierTo = cc.BezierTo or BaseClass(cc.BezierBy)

function cc.BezierTo:__init(t, c)
    self:initWithDuration(t, c)
end

function cc.BezierTo:initWithDuration(t, c)
    cc.ActionInterval.initWithDuration(self, t)
    self._toConfig = c
end

function cc.BezierTo:clone()
    return cc.BezierTo.New(self._duration, self._toConfig)
end

function cc.BezierTo:startWithTarget(target)
    cc.BezierBy.startWithTarget(self, target)
    self._config = {}
    self._config.control_1 = {x=0,y=0}
    self._config.control_1.x = self._toConfig.control_1.x - self._startPosition.x
    self._config.control_1.y = self._toConfig.control_1.y - self._startPosition.y
    self._config.control_2 = {x=0,y=0}
    self._config.control_2.x = self._toConfig.control_2.x - self._startPosition.x
    self._config.control_2.y = self._toConfig.control_2.y - self._startPosition.y

    self._config.end_pos = {x=0,y=0}
    self._config.end_pos.x = self._toConfig.end_pos.x - self._startPosition.x
    self._config.end_pos.y = self._toConfig.end_pos.y - self._startPosition.y
end

function cc.BezierTo:reverse()
    return nil
end

--DelayTime end