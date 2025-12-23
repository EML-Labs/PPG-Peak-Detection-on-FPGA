# PPG Peak Detection on FPGA
This project is focused to build a peak detection pipeline for PPG signals using FPGA part of the CS4363 - Hardware Description Languages module at the University of Moratuwa.


## System Architecture

The complete PPG peak detection system is organized as a modular pipeline:

```mermaid
graph TD
    %% Node Definitions
    Input[Raw PPG Input<br/>16-bit signed samples @ 100 Hz]
    
    BPF[Type-4 Bandpass Filter<br/>0.5-4 Hz<br/>IIR 4th-order Butterworth]
    
    ABS[Absolute Value Converter<br/>Maps negative to positive]
    
    MAF[Moving Average Filter<br/>N=30 samples<br/>Smoothing & Integration]
    
    LPF[Type-1 Lowpass Filter<br/>2 Hz<br/>IIR 1st-order]
    
    Peak[Peak Detector<br/>Threshold-based detection]
    
    Output([Peak Detection Output])

    %% Connections
    Input --> BPF
    BPF --> ABS
    ABS --> MAF
    MAF --> LPF
    LPF --> Peak
    Peak --> Output
```

---

## Development Environment Setup

### Setup the HDL compiler and GTKWave
> [!NOTE]
> Use the documentation provided in [here](https://github.com/EML-Labs/PPG-Peak-Detection-on-FPGA/wiki/Setup-Development-Environment)

### Setup a module with predefined structure
> [!TIP]
> Use the [Template Project](./../src/Template_Project/) with the documentation provided in [here](https://github.com/EML-Labs/PPG-Peak-Detection-on-FPGA/wiki/Setup-a-Module)


## Acknowledgements

The I2C Master module used in this project is adapted from the work of [I2C Master](https://github.com/aslak3/i2c-controller) by [Lawrence Manning](https://www.aslak.net/).

## Citation
If you use this work in your research, please cite the following paper:
```
@misc{eml2025ppg,
title={PPG Peak Detection on FPGA},
author={Weijith Wimalasiri and Yasantha Niroshan and Chathuranga Hettiarachchi},
year={2025},
note={Unpublished technical report. Available at: https://github.com/YourOrg/PPG-Peak-Detection-on-FPGA},
url={https://github.com/EML-Labs/PPG-Peak-Detection-on-FPGA}
}

@misc{eml2025example,
title={PPG Peak Detection Example Simulations},
author={Weijith Wimalasiri and Yasantha Niroshan},
year={2025},
note={Unpublished, included with the repository examples. Available at: https://github.com/EML-Labs/PPG-Peak-Detection-on-FPGA},
url={https://github.com/EML-Labs/PPG-Peak-Detection-on-FPGA}
}
```

## License
This project is licensed under the MIT License - see the [LICENSE](./LICENSE) file for details.