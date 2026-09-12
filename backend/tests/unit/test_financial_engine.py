import pytest
from app.schemas.finance import FinancialSimulationInput
from app.services.financial_engine import FinancialEngine


def test_calculate_emi_standard():
    # 1 Lakh at 10% for 12 months
    emi = FinancialEngine.calculate_emi(principal=100000.0, annual_rate_pct=10.0, tenure_months=12)
    assert emi == 8791.59


def test_calculate_emi_zero_interest():
    # 60,000 at 0% for 12 months -> 5,000/mo
    emi = FinancialEngine.calculate_emi(principal=60000.0, annual_rate_pct=0.0, tenure_months=12)
    assert emi == 5000.0


def test_calculate_emi_zero_principal():
    emi = FinancialEngine.calculate_emi(principal=0.0, annual_rate_pct=10.0, tenure_months=12)
    assert emi == 0.0


def test_calculate_emi_negative_or_zero_tenure():
    """Negative or zero tenure should safely return 0.0 EMI rather than divide by zero."""
    assert FinancialEngine.calculate_emi(principal=50000.0, annual_rate_pct=8.5, tenure_months=0) == 0.0
    assert FinancialEngine.calculate_emi(principal=50000.0, annual_rate_pct=8.5, tenure_months=-6) == 0.0
    assert FinancialEngine.calculate_emi(principal=-50000.0, annual_rate_pct=8.5, tenure_months=12) == 0.0


def test_calculate_emi_high_interest_rate():
    """Extreme interest rates (e.g. 48% micro-lender) compute mathematically correct EMI."""
    emi = FinancialEngine.calculate_emi(principal=10000.0, annual_rate_pct=48.0, tenure_months=6)
    assert emi > 0
    assert round(emi * 6, 2) > 10000.0


def test_financial_simulation_100pct_own_capital():
    """When entrepreneur funds 100% of the project, required loan and EMI must be 0 with safe affordability."""
    input_data = FinancialSimulationInput(
        total_project_cost=100000.0,
        own_capital=100000.0,
        annual_interest_rate_pct=10.0,
        tenure_months=12,
        projected_monthly_revenue=25000.0,
        projected_monthly_operating_cost=15000.0,
    )
    result = FinancialEngine.simulate(input_data)
    assert result.required_loan_amount == 0.0
    assert result.monthly_emi == 0.0
    assert result.total_interest_payable == 0.0
    assert result.is_affordable is True
    assert result.affordability_risk_level == "safe"
    assert result.debt_service_coverage_ratio == 99.0


def test_financial_simulation_safe_case():
    input_data = FinancialSimulationInput(
        total_project_cost=200000.0,
        own_capital=50000.0,  # Loan needed: 1,50,000
        annual_interest_rate_pct=9.5,
        tenure_months=24,
        projected_monthly_revenue=50000.0,
        projected_monthly_operating_cost=20000.0,  # Monthly profit: 30,000
    )
    result = FinancialEngine.simulate(input_data)
    assert result.required_loan_amount == 150000.0
    assert result.monthly_emi > 0
    assert result.is_affordable is True
    assert result.affordability_risk_level == "safe"
    assert result.debt_service_coverage_ratio > 1.25


def test_financial_simulation_tight_dscr_moderate_risk():
    """DSCR between 1.0 and 1.25 should be flagged as moderate risk."""
    # Monthly profit 10,000, EMI approx 9,000 -> DSCR ~ 1.11
    input_data = FinancialSimulationInput(
        total_project_cost=100000.0,
        own_capital=0.0,
        annual_interest_rate_pct=14.0,
        tenure_months=12,
        projected_monthly_revenue=25000.0,
        projected_monthly_operating_cost=15000.0,  # Profit = 10,000
    )
    result = FinancialEngine.simulate(input_data)
    assert result.monthly_emi > 8000
    assert result.debt_service_coverage_ratio < 1.25
    assert result.is_affordable is True
    assert result.affordability_risk_level == "moderate"


def test_financial_simulation_critical_loss():
    # Revenue doesn't cover operating cost
    input_data = FinancialSimulationInput(
        total_project_cost=100000.0,
        own_capital=20000.0,
        annual_interest_rate_pct=10.0,
        tenure_months=12,
        projected_monthly_revenue=15000.0,
        projected_monthly_operating_cost=20000.0,  # Loss of 5,000
    )
    result = FinancialEngine.simulate(input_data)
    assert result.is_affordable is False
    assert result.affordability_risk_level == "critical"


def test_amortization_preview_boundary():
    """Verify amortization schedule starts with initial principal and properly reduces."""
    schedule = FinancialEngine.generate_amortization_preview(
        principal=50000.0,
        annual_rate_pct=12.0,
        tenure_months=12,
        preview_months=6,
    )
    assert len(schedule) == 6
    assert schedule[0].month == 1
    assert schedule[0].opening_balance == 50000.0
    assert schedule[0].closing_balance < schedule[0].opening_balance
    assert schedule[5].month == 6
