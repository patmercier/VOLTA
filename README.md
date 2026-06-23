# VOLTA 
## VCO ADC Optimization Library and Toolbox for nonlinear Analysis
A distortion-centric framework for VCO-ADC design that incorporates the unconventional tradeoffs seen in ADC-direct architectures. The validated model gives realistic distortion-limited results, within 10\% of published silicon measurements, early in the system design process, without circuit design iterations or iterative differential equation solvers. The toolbox also includes a genetic algorithm-based heuristic optimizer with associated setup, utility, and visualization functions. The optimizer efficiently runs large populations, with multiple non-linear constraints, to maximize the Schreier Figure-of-Merit without manual knob tuning, while providing useful insight into design tradeoffs. 

## Introduction
The rapid growth of IoT devices necessitates efficient AFE-ADCs that direcly interface with a sensor to combine signal conditioning and digitization in a single block. VCO-ADCs are highly viable, digital intensive architectures that scale well to low power and area, with much of the literature focusing on mitigating the VCO non-linearity problem. While these techniques have been effective, the typical design process involves iteration between circuit and model simulators, both of which run transient simulations, leading to a time-consuming and laborious process, with a steep learning curve for the unconventional trade-offs. 

Prior-art in design methodology, toolboxes and automation that address this issue by increasing efficiency and adding automation have one or more of the following drawbacks. Firstly, there is a high level of abstraction or qualitative analysis that does not necessarily translate to quantitative to circuit level parameters, which is left to circuit simulators. Secondly, most toolboxes and design methods that include quantification and circuit non-idealities ignore distortion at the initial system design phase. This is unsuitable for VCO-ADCs since the whole design process revolves around mitigating distortion. They are also meant for traditional ADCs at the end of a signal chain, focusing on Noise Transfer Function (NTF) design for a target Signal-To-Quantization-Noise Ratio (SQNR) rather than the input impedance, distortion, and low noise floor. Thirdly, lack of automated optimization that includes distortion tradeoffs in these flows can lead to sub-optimal designs, manual knob tuning, and iterative work in trying to maximize the Schreier Figure-of-Merit. Flows that use optimization focus on re-use rather than design. Because the model is trained on a particular design, the optimizer only generates ADCs closest to the pre-existing design. It does not start from fundamental tradeoffs and cannot be modified for a new design.

This work provides an open-source VCO-ADC model framework and design methodology that offers the following benefits :
- Distortion-centric, addressing the unconventional trade-offs of AFE-ADCs using the Volterra-series to analytically capture the effect of distortion on spurious tones and noise folding.
- Fully analytical, without solving differential equations from a transient simulation 
- Genetic algorithm-based heuristic optimizer with associated setup, utility, and visualization functions to maximize Schreier Figure-of-Merit over large populations
- Well-documented, modular library that acts as a framework amenable to customization for specific designs

## Repository Structure
VOLTA-Lib is a MATLAB Package with the following structure
VOLTA-Lib/
├── README.md
├── LICENSE
└── +VOLTA/                       % Top-Level MATLAB package
    ├── outputs/                  % Genetic algorithm output data
    ├── +visualization/           % Plotting and visualization functions
    ├── +utilities/               % General-purpose helper functions
    ├── +scripts/                 % Visualization, validation and optimization execution wrapper scripts
    │   └── +configs/             % Parameter and variable configuration sets
    ├── +optimization/            % Optimization functions
    └── +model/                   % Core ADC modeling framework
        ├── evaluateAdcModel.m    % Model evaluation entry point
        ├── Adc.m                 % ADC system class definition
        └── +variants/            % Variant model implementations

## Package Hierarchy
The repository uses MATLAB package folders (prefixed with +) to define a hierarchical namespace.

Each + folder introduces one namespace level.

Examples:

- +VOLTA → VOLTA

- +VOLTA/+model → VOLTA.model

- +VOLTA/+scripts/+configs → VOLTA.scripts.configs

Function documenation for all package modules can be accessed as follows : 
- help VOLTA.utilities.setupVariables
- help VOLTA.model.evaluateAdcModel

## Installation

1. Download or clone the repository to your local machine.
2. Add the `VOLTA-Lib/` folder to your MATLAB path. For example:
- addpath('path/to/VOLTA-Lib')
Use which VOLTA.model.evaluateAdcModel to check if configured correctly
3. Function calls are done using nested hierarchical namespace described in "Package Hierarchy" section

## Citation
If you used this code and find it helpful to your research, please consider citing our paper:

```
@article{
}
```

```
Nitundil S, Burns R, Mercier P P. Fully Analytical Modeling and Heuristic Optimization of VCO-ADCs with Volterra Series based Noise Folding Quantification. 
```
