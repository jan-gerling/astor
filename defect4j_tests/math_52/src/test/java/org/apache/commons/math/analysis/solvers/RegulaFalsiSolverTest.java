/*
 * Licensed to the Apache Software Foundation (ASF) under one or more
 * contributor license agreements.  See the NOTICE file distributed with
 * this work for additional information regarding copyright ownership.
 * The ASF licenses this file to You under the Apache License, Version 2.0
 * (the "License"); you may not use this file except in compliance with
 * the License.  You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package org.apache.commons.math.analysis.solvers;

/**
 * Test case for {@link RegulaFalsiSolver Regula Falsi} solver.
 *
 * @version $Id$
 */
public final class RegulaFalsiSolverTest extends BaseSecantSolverAbstractTest {
    /** {@inheritDoc} */
    protected UnivariateRealSolver getSolver() {
        return new RegulaFalsiSolver();
    }

    /** {@inheritDoc} */
    protected int[] getQuinticEvalCounts() {
        // While the Regula Falsi method guarantees convergence, convergence
        // may be extremely slow. The last test case does not converge within
        // even a million iterations. As such, it was disabled.
        return new int[] {3, 7, 8, 19, 18, 11, 67, 55, 288, 151, -1};
    }
}
