"""Build the dbt seed stats19_code_lookup.csv from the DfT STATS19 data guide."""
from pathlib import Path

import pandas as pd

GUIDE = Path("Data/dft-road-casualty-statistics-road-safety-open-dataset-data-guide-2025.xlsx")
OUT = Path("Airflow/dags/dbt/road_safety/seeds/stats19_code_lookup.csv")


def find_code_sheet(path: Path) -> pd.DataFrame:
    """Find the sheet and header row that hold the code list (field name / code / label)."""
    xl = pd.ExcelFile(path)
    for sheet in xl.sheet_names:
        for header_row in range(0, 5):
            df = pd.read_excel(path, sheet_name=sheet, header=header_row)
            cols = [str(c).strip().lower() for c in df.columns]
            if any("field" in c for c in cols) and any("label" in c for c in cols) and any("code" in c for c in cols):
                print(f"Using sheet '{sheet}', header row {header_row}: {list(df.columns)}")
                df.columns = cols
                return df
    raise ValueError(f"No code-list sheet found. Sheets: {xl.sheet_names}")


def pick(cols, word):
    return next(c for c in cols if word in c)


df = find_code_sheet(GUIDE)
table_col = next((c for c in df.columns if "table" in c), None)

out = pd.DataFrame({
    "table_name": df[table_col].astype(str).str.strip().str.lower() if table_col else "all",
    "field_name": df[pick(df.columns, "field")].astype(str).str.strip().str.lower(),
    "code": pd.to_numeric(df[pick(df.columns, "code")], errors="coerce"),
    "label": df[pick(df.columns, "label")].astype(str).str.strip(),
})

# keep real numeric codes only (drops format notes like "DD/MM/YYYY" and blank rows)
out = out.dropna(subset=["code"])
out = out[out["label"].ne("") & out["label"].ne("nan")]
out["code"] = out["code"].astype(int)
out = out.drop_duplicates(subset=["table_name", "field_name", "code"])

OUT.parent.mkdir(parents=True, exist_ok=True)
out.to_csv(OUT, index=False)
print(f"{len(out)} rows written to {OUT}")
print(out["field_name"].value_counts().head(15))