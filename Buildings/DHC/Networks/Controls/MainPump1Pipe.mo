within Buildings.DHC.Networks.Controls;
model MainPump1Pipe
  "Main pump controller for 1 pipe networks, developed for reservoir network main circulation loop"
  parameter Integer nMix(min=1)
    "Number of mixing points after the substations";
  parameter Integer nSou(min=1)
    "Number of heat sources (and heat sinks)";
  parameter Integer nBui(min=1)
    "Number of heat sources (and heat sinks)";
  parameter Real yPumMin(min=0.01, max=1, final unit="1") = 0.05
    "Minimum pump speed";
  parameter Real TMin(
    final unit="K",
    displayUnit="degC",
    final quantity="ThermodynamicTemperature") = 281.15
    "Minimum loop temperature";
  parameter Real TMax(
    final unit="K",
    displayUnit="degC",
    final quantity="ThermodynamicTemperature") = 291.15
    "Maximum loop temperature";
  parameter Real dTSlo(
    final min=1,
    final quantity="TemperatureDifference",
    final unit="K") = 2
    "Temperature difference for slope";
  parameter Boolean use_temperatureShift = false
    "Set to false to disable temperature shift of slopes";
  parameter Boolean use_constantHeaTemShift = true
    "Set to false to disable constant temperature shift of TMax when only heating is occurring";
  parameter Real offTMax(
    final quantity="TemperatureDifference",
    final unit="K")= 2
    "TMax constant temperature shift";
  final parameter Real delta(
    final quantity="TemperatureDifference",
    final unit="K")=if use_temperatureShift then TMax - TMin - 3*dTSlo else 0
    "Maximum shift of slopes";
  parameter Real dTSou_nominal[nSou](
    each min=0,
    each final quantity="TemperatureDifference",
    each final unit="K") = fill(4, nSou)
    "Nominal temperature difference over source";
  parameter Real k=0.01
    "Gain of controller that shifts upper and lower temperature setpoints";
  parameter Real Ti(
    displayUnit="min",
    final unit="s",
    final quantity="Time") = 300
    "Time constant of integrator block that shifts upper and lower temperature setpoints";
  parameter Real PpumCooThr=100
    "Threshold for comparison for pump cooling power";
  parameter Real hysPpumCoo=10 "Hysteresis for cooling pump power threshold";

  Buildings.Controls.OBC.CDL.Interfaces.RealInput TMix[nMix](
    each final unit="K",
    each displayUnit="degC")
    "Temperatures at the mixing points"
    annotation (Placement(transformation(extent={{-140,100},{-100,140}}),
        iconTransformation(extent={{-140,60},{-100,100}})));
  Buildings.Controls.OBC.CDL.Interfaces.RealInput TSouIn[nSou](
    each final unit="K",
    each displayUnit="degC")
    "Temperatures at the inlets of the sources"
    annotation (Placement(transformation(extent={{-140,20},{-100,60}}),
        iconTransformation(extent={{-140,20},{-100,60}})));
  Buildings.Controls.OBC.CDL.Interfaces.RealInput TSouOut[nSou](
    each final unit="K",
    each displayUnit="degC")
    "Temperatures at the outlets of the sources"
    annotation (Placement(transformation(extent={{-140,-80},{-100,-40}}),
        iconTransformation(extent={{-140,-60},{-100,-20}})));
  Buildings.Controls.OBC.CDL.Interfaces.RealInput QCoo_flow[nBui](
    each final unit="W")
    "Cooling power required by each building"
    annotation (Placement(transformation(extent={{-142,-190},{-102,-150}}),
        iconTransformation(extent={{-140,-100},{-100,-60}})));
  Buildings.Controls.OBC.CDL.Interfaces.RealOutput y(min=0, max=1, unit="1")
    "Pump control signal"
    annotation (Placement(transformation(extent={{160,-40},{200,0}}),
        iconTransformation(extent={{100,-20},{140,20}})));

  Buildings.Controls.OBC.CDL.Reals.MultiMin TMixMin(
    final nin=nMix,
    y(final unit="K",
      displayUnit="degC"))
    "Minimum temperature at mixing points"
    annotation (Placement(transformation(extent={{-70,-30},{-50,-10}})));
  Buildings.Controls.OBC.CDL.Reals.MultiMax TMixMax(
    final nin=nMix,
    y(final unit="K", displayUnit="degC"))
    "Maximum temperature at mixing points"
    annotation (Placement(transformation(extent={{-70,10},{-50,30}})));
  Buildings.Controls.OBC.CDL.Reals.MultiSum mulSum(
    k=fill(1, nSou), nin=nSou)
    annotation (Placement(transformation(extent={{-50,-130},{-30,-110}})));
  Buildings.Controls.OBC.CDL.Reals.Subtract dTSou[nSou]
    "Temperature differences over source"
    annotation (Placement(transformation(extent={{-78,-130},{-58,-110}})));
  Buildings.Controls.OBC.CDL.Reals.MultiplyByParameter dTSou_nor(
    final k=1/(sum(dTSou_nominal)))
    "Normalization of temperature difference over source"
    annotation (Placement(transformation(extent={{-20,-130},{0,-110}})));
  Buildings.Controls.OBC.CDL.Reals.PID conShi(
    controllerType=Buildings.Controls.OBC.CDL.Types.SimpleController.PI,
    final k=k,
    Ti(displayUnit="min") = Ti,
    final yMax=1,
    final yMin=-1)
    "Controller to shift the min/max slopes"
    annotation (Placement(transformation(extent={{10,-110},{30,-90}})));
  Buildings.Controls.OBC.CDL.Reals.Sources.Constant zer(k=0)
    "Set point for source dT"
    annotation (Placement(transformation(extent={{-50,-90},{-30,-70}})));
  Buildings.Controls.OBC.CDL.Reals.Line uppCur "Upper curve"
    annotation (Placement(transformation(extent={{30,10},{50,30}})));
  Buildings.Controls.OBC.CDL.Reals.Sources.Constant one(k=1) "Constant 1"
    annotation (Placement(transformation(extent={{-70,70},{-50,90}})));
  Buildings.Controls.OBC.CDL.Reals.Sources.Constant yMin(
    final k=yPumMin)
    "Minimum pump speed"
    annotation (Placement(transformation(extent={{-72,40},{-52,60}})));
  Buildings.Controls.OBC.CDL.Reals.Sources.Constant TMax_nominal(
    final k=TMax)
    "Maximum temperature"
    annotation (Placement(transformation(extent={{-70,150},{-50,170}})));
  Buildings.Controls.OBC.CDL.Reals.Add TMax_upper(
    y(final unit="K", displayUnit="degC"))
    "Upper value of upper slope after shifting it"
    annotation (Placement(transformation(extent={{-30,150},{-10,170}})));
  Buildings.Controls.OBC.CDL.Reals.Max sPos "Positive shift"
    annotation (Placement(transformation(extent={{60,-70},{80,-50}})));
  Buildings.Controls.OBC.CDL.Reals.Min sNeg "Negative shift"
    annotation (Placement(transformation(extent={{60,-150},{80,-130}})));
  Buildings.Controls.OBC.CDL.Reals.AddParameter TMax_lower(
    final p=-dTSlo,
    y(final unit="K", displayUnit="degC"))
    "Minimum temperatuer value of upper slope after shifting it"
    annotation (Placement(transformation(extent={{10,149},{30,171}})));
  Buildings.Controls.OBC.CDL.Reals.Line lowCur "Lower curve"
    annotation (Placement(transformation(extent={{30,-30},{50,-10}})));
  Buildings.Controls.OBC.CDL.Reals.Sources.Constant TMin_nominal(
    final k=TMin)
    "Minimum temperature"
    annotation (Placement(transformation(extent={{-70,110},{-50,130}})));
  Buildings.Controls.OBC.CDL.Reals.Add TMin_lower(
    y(unit="K", displayUnit="degC"))
    "Lower value of lower slope after shifting it"
    annotation (Placement(transformation(extent={{-30,110},{-10,130}})));
  Buildings.Controls.OBC.CDL.Reals.AddParameter TMin_upper(
    final p=dTSlo,
    y(final unit="K", displayUnit="degC"))
    "Maximum temperatuer value of lower slope after shifting it"
    annotation (Placement(transformation(extent={{10,110},{30,130}})));
  Buildings.Controls.OBC.CDL.Reals.Max ySetPum "Change in pump signal"
    annotation (Placement(transformation(extent={{60,-10},{80,10}})));
  Buildings.Controls.OBC.CDL.Reals.Switch swi2
    "Switch on and off constant offset"
    annotation (Placement(transformation(extent={{100,-190},{120,-210}})));
  Buildings.Controls.OBC.CDL.Logical.Sources.Constant actMod(
    final k=use_constantHeaTemShift) "True: activate mode"
    annotation (Placement(transformation(extent={{-20,-210},{0,-190}})));
  Buildings.Controls.OBC.CDL.Reals.GreaterThreshold greThr(
    final t=PpumCooThr,
    final h=hysPpumCoo,
    final pre_y_start=false)
    "Check pump consumption higher than zero"
    annotation (Placement(transformation(extent={{-20,-180},{0,-160}})));
  Buildings.Controls.OBC.CDL.Logical.And and2
    "With pump consumption and activate mode"
    annotation (Placement(transformation(extent={{20,-180},{40,-160}})));
  Buildings.Controls.OBC.CDL.Reals.MultiSum mulSum1(
    final k=fill(1,nBui),
    final nin=nBui) "Sum of all pump consumptions"
    annotation (Placement(transformation(extent={{-94,-180},{-74,-160}})));
  Buildings.Controls.OBC.CDL.Reals.MultiplyByParameter gai(
    final k=-delta)
    "Gain factor"
    annotation (Placement(transformation(extent={{100,-70},{120,-50}})));
  Buildings.Controls.OBC.CDL.Reals.MultiplyByParameter gai2(
    final k=-delta)
    "Gain factor"
    annotation (Placement(transformation(extent={{100,-150},{120,-130}})));
  Buildings.Controls.OBC.CDL.Reals.Sources.Constant offTMaxExp(
    final k=offTMax)
    "Constant TMax offset"
    annotation (Placement(transformation(extent={{60,-180},{80,-160}})));
  Buildings.Controls.OBC.CDL.Reals.Add Add(
    y(unit="K", displayUnit="degC"))
    "If use_heaTemShift and not use_temperatureShift use constant offset, if use_temperatureShift use PI"
    annotation (Placement(transformation(extent={{10,-10},{-10,10}},
        rotation=0, origin={90,140})));
  Buildings.Controls.OBC.CDL.Reals.MultiplyByParameter gai1(
    final k=-1)
    "Gain factor"
    annotation (Placement(transformation(extent={{-60,-180},{-40,-160}})));
equation
  connect(TMix, TMixMin.u) annotation (Line(points={{-120,120},{-80,120},{-80,-20},
          {-72,-20}}, color={0,0,127}));
  connect(TMix, TMixMax.u) annotation (Line(points={{-120,120},{-80,120},{-80,20},
          {-72,20}}, color={0,0,127}));
  connect(mulSum.y, dTSou_nor.u)
    annotation (Line(points={{-28,-120},{-22,-120}}, color={0,0,127}));
  connect(dTSou_nor.y, conShi.u_m)
    annotation (Line(points={{2,-120},{20,-120},{20,-112}},  color={0,0,127}));
  connect(conShi.u_s, zer.y) annotation (Line(points={{8,-100},{0,-100},{0,
          -80},{-28,-80}}, color={0,0,127}));
  connect(uppCur.u, TMixMax.y)
    annotation (Line(points={{28,20},{-48,20}}, color={0,0,127}));
  connect(uppCur.f1, yMin.y) annotation (Line(points={{28,24},{-30,24},{-30,50},
          {-50,50}}, color={0,0,127}));
  connect(uppCur.f2, one.y) annotation (Line(points={{28,12},{-26,12},{-26,80},{
          -48,80}}, color={0,0,127}));
  connect(TMax_nominal.y, TMax_upper.u1)
    annotation (Line(points={{-48,160},{-40,160},{-40,166},{-32,166}},
          color={0,0,127}));
  connect(zer.y, sPos.u1) annotation (Line(points={{-28,-80},{46,-80},{46,-54},
          {58,-54}}, color={0,0,127}));
  connect(zer.y, sNeg.u1) annotation (Line(points={{-28,-80},{46,-80},{46,
          -134},{58,-134}}, color={0,0,127}));
  connect(conShi.y, sPos.u2) annotation (Line(points={{32,-100},{50,-100},{50,-66},
          {58,-66}}, color={0,0,127}));
  connect(conShi.y, sNeg.u2) annotation (Line(points={{32,-100},{50,-100},{50,-146},
          {58,-146}},color={0,0,127}));
  connect(TMax_lower.u, TMax_upper.y)
    annotation (Line(points={{8,160},{-8,160}},   color={0,0,127}));
  connect(uppCur.x1, TMax_lower.y) annotation (Line(points={{28,28},{20,28},{
          20,80},{40,80},{40,160},{32,160}}, color={0,0,127}));
  connect(TMax_upper.y, uppCur.x2) annotation (Line(points={{-8,160},{0,160},
          {0,16},{28,16}}, color={0,0,127}));
  connect(TMixMin.y, lowCur.u)
    annotation (Line(points={{-48,-20},{28,-20}}, color={0,0,127}));
  connect(TMin_nominal.y, TMin_lower.u1) annotation (Line(points={{-48,120},{
          -40,120},{-40,126},{-32,126}}, color={0,0,127}));
  connect(TMin_lower.y, TMin_upper.u)
    annotation (Line(points={{-8,120},{8,120}}, color={0,0,127}));
  connect(TMin_upper.y, lowCur.x2) annotation (Line(points={{32,120},{36,120},
          {36,84},{16,84},{16,-24},{28,-24}}, color={0,0,127}));
  connect(TMin_lower.y, lowCur.x1) annotation (Line(points={{-8,120},{-4,120},
          {-4,-12},{28,-12}}, color={0,0,127}));
  connect(lowCur.f1, one.y) annotation (Line(points={{28,-16},{-26,-16},{-26,80},
          {-48,80}},color={0,0,127}));
  connect(lowCur.f2, yMin.y) annotation (Line(points={{28,-28},{-30,-28},{-30,
          50},{-50,50}}, color={0,0,127}));
  connect(uppCur.y, ySetPum.u1)
    annotation (Line(points={{52,20},{56,20},{56,6},{58,6}}, color={0,0,127}));
  connect(lowCur.y, ySetPum.u2) annotation (Line(points={{52,-20},{56,-20},{56,-6},
          {58,-6}}, color={0,0,127}));
  connect(ySetPum.y, y)
    annotation (Line(points={{82,0},{132,0},{132,-20},{180,-20}}, color={0,0,127}));
  connect(TSouOut, dTSou.u1) annotation (Line(points={{-120,-60},{-94,-60},{-94,
          -114},{-80,-114}}, color={0,0,127}));
  connect(TSouIn, dTSou.u2) annotation (Line(points={{-120,40},{-90,40},{-90,-126},
          {-80,-126}}, color={0,0,127}));
  connect(actMod.y, and2.u2) annotation (Line(points={{2,-200},{10,-200},{10,-178},
          {18,-178}}, color={255,0,255}));
  connect(and2.y, swi2.u2) annotation (Line(points={{42,-170},{52,-170},{52,-200},
          {98,-200}},  color={255,0,255}));
  connect(dTSou.y, mulSum.u)
    annotation (Line(points={{-56,-120},{-52,-120}}, color={0,0,127}));
  connect(greThr.y, and2.u1) annotation (Line(points={{2,-170},{18,-170}},
         color={255,0,255}));
  connect(QCoo_flow, mulSum1.u)
    annotation (Line(points={{-122,-170},{-96,-170}}, color={0,0,127}));
  connect(sPos.y, gai.u)
    annotation (Line(points={{82,-60},{98,-60}}, color={0,0,127}));
  connect(sNeg.y, gai2.u)
    annotation (Line(points={{82,-140},{98,-140}}, color={0,0,127}));
  connect(gai2.y, TMin_lower.u2) annotation (Line(points={{122,-140},{126,-140},
          {126,100},{-40,100},{-40,114},{-32,114}}, color={0,0,127}));
  connect(swi2.y, Add.u1) annotation (Line(points={{122,-200},{150,-200},{150,146},
          {102,146}}, color={0,0,127}));
  connect(gai.y, Add.u2) annotation (Line(points={{122,-60},{140,-60},{140,132},
          {102,132},{102,134}}, color={0,0,127}));
  connect(Add.y, TMax_upper.u2) annotation (Line(points={{78,140},{-38,140},{-38,
          154},{-32,154}}, color={0,0,127}));
  connect(offTMaxExp.y, swi2.u3) annotation (Line(points={{82,-170},{90,-170},{90,
          -192},{98,-192}}, color={0,0,127}));
  connect(zer.y, swi2.u1) annotation (Line(points={{-28,-80},{46,-80},{46,-208},
          {98,-208}},  color={0,0,127}));
  connect(mulSum1.y, gai1.u)
    annotation (Line(points={{-72,-170},{-62,-170}}, color={0,0,127}));
  connect(gai1.y, greThr.u)
    annotation (Line(points={{-38,-170},{-22,-170}}, color={0,0,127}));
  annotation (
    defaultComponentName="conPum",
    Diagram(coordinateSystem(extent={{-100,-220},{160,180}})), Icon(
        coordinateSystem(extent={{-100,-100},{100,100}}), graphics={
                                Rectangle(
        extent={{-100,-100},{100,100}},
        lineColor={0,0,127},
        fillColor={255,255,255},
        fillPattern=FillPattern.Solid),
        Text(
          extent={{-96,88},{-78,74}},
          textColor={0,0,127},
          textString="TMix"),
        Text(
          extent={{-96,52},{-68,28}},
          textColor={0,0,127},
          textString="TSouIn"),
        Text(
          extent={{-96,-24},{-64,-58}},
          textColor={0,0,127},
          textString="TSouOut"),
        Text(
          extent={{80,12},{102,-8}},
          textColor={0,0,127},
          textString="y"),
        Ellipse(
          extent={{-52,50},{50,-50}},
          lineColor={0,0,0},
          fillColor={255,255,255},
          fillPattern=FillPattern.Solid),
        Polygon(
          points={{0,50},{0,-50},{52,0},{0,50}},
          lineColor={0,0,0},
          lineThickness=1,
          fillColor={0,0,0},
          fillPattern=FillPattern.Solid),
        Text(
          extent={{-96,-62},{-64,-96}},
          textColor={0,0,127},
          textString="QCoo_flow"),      Text(
        extent={{-120,140},{120,100}},
        textString="%name",
        textColor={0,0,255})}),
    Documentation(revisions="<html>
<ul>
<li>
April 3, 2023, by Ettore Zanetti:<br/>
Added parameter <code>use_constantHeaTemShift</code><br/>
This is for
<a href=\"https://github.com/lbl-srg/modelica-buildings/issues/3431\">issue 3431</a>.
</li>
<li>
September 12, 2019, by Michael Wetter:<br/>
First implementation.
</li>
</ul>
</html>",
  info="<html>
<p>
Controller for the main circulation pump.
</p>
<p>
This controller adjusts the pump speed in order to reduce it, unless
the water temperature at the mixing points after the agents in the district is too high
or too low, as measured by the difference to <code>TMin</code> and <code>TMax</code>.
In that case, the pump speed is increased to prevent the loop getting too cold or too warm.
The control is as follows:
Let <code>TMixMin</code> and <code>TMixMax</code> be the
minimum and maximum mixing temperatures.
If <code>TMax-TMixMax</code> or <code>TMixMin-TMin</code> is too small,
the pump speed is increased.
If the difference is larger than <code>dTSlo</code>, then the pump speed
is set to the minimum speed <code>yPumMin</code>.
This calculation is done for both, <code>TMixMin</code> and <code>TMixMax</code>.
The actual pump speed is then the larger of the two pump signals.
Therefore, the pump speeds are calculated as shown in the figure below.
</p>
<p>
<br/>
<img alt=\"Image of the control that adjusts the pump speed\"
src=\"modelica://Buildings/Resources/Images/DHC/Networks/Controls/MainPump.png\"/>
<br/>
</p>
<p>
Moreover, if the parameter <code>use_temperatureShift</code> is set to <code>true</code>,
then the district loop temperature is adjusted by changing the mass
flow rate of the pump to increase the overall efficiency if there is net
cooling or net heating on the loop. Specifically,
if the district heating or cooling loop is in net heating (cooling) mode,
it may be favorable to increase (decrease) the loop temperature, which can
be done by increasing the pump speed. Whether the loop
is in heating or cooling mode is determined based on the temperature differences
across the loop sources, which are the inputs <code>TSouIn</code> and <code>TSouOut</code>.
Each heat source or sink needs to be connected to one element of these
vectorized input signals.
This net difference is then used with a PI-controller to determine how much the slopes
should be shifted in order to increase the pump speed.
The shift of these slopes is indicated by the arrows
in the figure.
Note that this controller must be configured to be slow reacting, as it requires the
feedback from the district heating and cooling loop. Furthermore, if the parameter
<code>use_constantHeaTemShift</code> is set to <code>true</code>, then a constant temperature
offset <code>offTMax</code> is added when only heating is present, this determination is done
by checking that the cooling demand for each energy transfer station via
<code>QCoo</code> is close to zero. This mode can used by itself or in conjuction with <code>use_temperatureShift</code>.
</p>
<p>
For a typical usage of this controller, see
<a href=\"modelica://Buildings.DHC.Examples.Combined.SeriesVariableFlow\">
Buildings.DHC.Examples.Combined.SeriesVariableFlow</a>.
</p>
</html>"));
end MainPump1Pipe;
