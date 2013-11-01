within Buildings.Electrical.Transmission.Functions;
function lineInductance
  input Modelica.SIunits.Length Length "Length of the cable";
  input Buildings.Electrical.Types.VoltageLevel level;
  input Buildings.Electrical.Transmission.LowVoltageCables.Cable cable_low;
  input Buildings.Electrical.Transmission.MediumVoltageCables.Cable cable_med;
  output Modelica.SIunits.Inductance L;
protected
  parameter Modelica.SIunits.Frequency f = 50
    "Frequency considered in the definition of cables properties";
  parameter Modelica.SIunits.AngularVelocity omega = 2*Modelica.Constants.pi*f;
algorithm

  if level == Buildings.Electrical.Types.VoltageLevel.Low then
    L := (cable_low.XCha/omega)*Length;
  elseif level == Buildings.Electrical.Types.VoltageLevel.Medium then
    L := (cable_low.XCha/omega)*Length;
  elseif level == Buildings.Electrical.Types.VoltageLevel.High then
    L := (cable_low.XCha/omega)*Length;
  else
    Modelica.Utilities.Streams.print("Warning: the voltage level does not match one of the three available: Low, Medium or High " +
        String(level) + ". A Low level has been choose as default.");
  end if;

end lineInductance;