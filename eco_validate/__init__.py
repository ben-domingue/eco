"""eco-validate: check a table against the eco data standard (standard.md).

    from eco_validate import validate_file, validate_frame
    report = validate_file("output/kery_2005_mallard_count.csv")
    report.ok, report.conforms, report.nonconforming, report.findings
"""
from .core import eco_to_irw, format_report, validate_file, validate_frame
from .model import CLAUSES, PROFILES, STANDARD_VERSION, Finding, Report, exit_code

__version__ = "0.1.0"
__all__ = ["validate_file", "validate_frame", "format_report", "eco_to_irw",
           "Finding", "Report", "CLAUSES", "PROFILES", "STANDARD_VERSION",
           "exit_code", "__version__"]
