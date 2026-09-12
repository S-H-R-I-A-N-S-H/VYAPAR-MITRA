from datetime import datetime
from typing import Any, List, Optional
from pydantic import BaseModel, Field


class SurveyQuestionItem(BaseModel):
    id: str
    question_text: str
    question_type: str = Field(description="multiple_choice, numeric, scale, text")
    options: List[str] = Field(default_factory=list)
    target_respondent: str = Field(default="customer", description="customer, competitor, supplier, retailer")


class SurveyCreate(BaseModel):
    research_project_id: str
    title: str
    target_respondent_type: str
    questions: List[SurveyQuestionItem]


class SurveyResponseSubmission(BaseModel):
    survey_id: str
    respondent_identifier: Optional[str] = None
    answers: dict = Field(description="Map of question_id to answer value")
    collector_notes: Optional[str] = None
    location_coordinates: Optional[dict] = None
