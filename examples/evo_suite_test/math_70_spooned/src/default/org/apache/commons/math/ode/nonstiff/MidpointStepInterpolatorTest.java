package org.apache.commons.math.ode.nonstiff;


public class MidpointStepInterpolatorTest {
	@org.junit.Test
	public void testDerivativesConsistency() throws org.apache.commons.math.ode.DerivativeException, org.apache.commons.math.ode.IntegratorException {
		org.apache.commons.math.ode.TestProblem3 pb = new org.apache.commons.math.ode.TestProblem3();
		double step = ((pb.getFinalTime()) - (pb.getInitialTime())) * 0.001;
		org.apache.commons.math.ode.nonstiff.MidpointIntegrator integ = new org.apache.commons.math.ode.nonstiff.MidpointIntegrator(step);
		org.apache.commons.math.ode.sampling.StepInterpolatorTestUtils.checkDerivativesConsistency(integ, pb, 1.0E-10);
	}

	@org.junit.Test
	public void serialization() throws java.io.IOException, java.lang.ClassNotFoundException, org.apache.commons.math.ode.DerivativeException, org.apache.commons.math.ode.IntegratorException {
		org.apache.commons.math.ode.TestProblem1 pb = new org.apache.commons.math.ode.TestProblem1();
		double step = ((pb.getFinalTime()) - (pb.getInitialTime())) * 0.001;
		org.apache.commons.math.ode.nonstiff.MidpointIntegrator integ = new org.apache.commons.math.ode.nonstiff.MidpointIntegrator(step);
		integ.addStepHandler(new org.apache.commons.math.ode.ContinuousOutputModel());
		integ.integrate(pb, pb.getInitialTime(), pb.getInitialState(), pb.getFinalTime(), new double[pb.getDimension()]);
		java.io.ByteArrayOutputStream bos = new java.io.ByteArrayOutputStream();
		java.io.ObjectOutputStream oos = new java.io.ObjectOutputStream(bos);
		for (org.apache.commons.math.ode.sampling.StepHandler handler : integ.getStepHandlers()) {
			oos.writeObject(handler);
		}
		org.junit.Assert.assertTrue(((bos.size()) > 98000));
		org.junit.Assert.assertTrue(((bos.size()) < 99000));
		java.io.ByteArrayInputStream bis = new java.io.ByteArrayInputStream(bos.toByteArray());
		java.io.ObjectInputStream ois = new java.io.ObjectInputStream(bis);
		org.apache.commons.math.ode.ContinuousOutputModel cm = ((org.apache.commons.math.ode.ContinuousOutputModel)(ois.readObject()));
		java.util.Random random = new java.util.Random(347588535632L);
		double maxError = 0.0;
		for (int i = 0 ; i < 1000 ; ++i) {
			double r = random.nextDouble();
			double time = (r * (pb.getInitialTime())) + ((1.0 - r) * (pb.getFinalTime()));
			cm.setInterpolatedTime(time);
			double[] interpolatedY = cm.getInterpolatedState();
			double[] theoreticalY = pb.computeTheoreticalState(time);
			double dx = (interpolatedY[0]) - (theoreticalY[0]);
			double dy = (interpolatedY[1]) - (theoreticalY[1]);
			double error = (dx * dx) + (dy * dy);
			if (error > maxError) {
				maxError = error;
			} 
		}
		org.junit.Assert.assertTrue((maxError < 1.0E-6));
	}
}

