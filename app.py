import streamlit as st
import pandas as pd
import sqlite3

# -----------------------------
# Setup
# -----------------------------
st.set_page_config(page_title="IPL SQL Dashboard", layout="wide")
st.title("🏏 IPL SQL Driven Dashboard")


# -----------------------------
# Load CSV into SQLite
# -----------------------------
@st.cache_resource
def load_db():
    conn = sqlite3.connect(":memory:", check_same_thread=False)
    df = pd.read_csv("iplmatches.csv")
    df.to_sql("iplmatches", conn, index=False, if_exists="replace")
    return conn


conn = load_db()

# -----------------------------
# Sidebar Filters
# -----------------------------
st.sidebar.header("Filters")

season = st.sidebar.multiselect(
    "Season", pd.read_sql("SELECT DISTINCT Season FROM iplmatches", conn)["Season"]
)

team = st.sidebar.multiselect(
    "Team",
    pd.read_sql(
        """
        SELECT team1 AS team FROM iplmatches
        UNION
        SELECT team2 FROM iplmatches
    """,
        conn,
    )["team"],
)

venue = st.sidebar.multiselect(
    "Venue", pd.read_sql("SELECT DISTINCT Venue FROM iplmatches", conn)["Venue"]
)

city = st.sidebar.multiselect(
    "City", pd.read_sql("SELECT DISTINCT City FROM iplmatches", conn)["City"]
)

# -----------------------------
# Dynamic WHERE clause
# -----------------------------
conditions = []

if season:
    conditions.append(f"Season IN ({','.join(map(str, season))})")

if team:
    team_list = ",".join([f"'{t}'" for t in team])
    conditions.append(f"(team1 IN ({team_list}) OR team2 IN ({team_list}))")

if venue:
    venue_list = ",".join([f"'{v}'" for v in venue])
    conditions.append(f"Venue IN ({venue_list})")

if city:
    city_list = ",".join([f"'{c}'" for c in city])
    conditions.append(f"City IN ({city_list})")

where_clause = " AND ".join(conditions)
if where_clause:
    where_clause = "WHERE " + where_clause

# -----------------------------
# 🎲 Toss Impact (YOUR QUERY)
# -----------------------------
st.subheader("🎲 Toss Impact")

query = f"""
SELECT 
    COUNT(*) AS total_matches,
    SUM(CASE WHEN TossWinner = WinningTeam THEN 1 ELSE 0 END) AS toss_winner_wins,
    ROUND(
        SUM(CASE WHEN TossWinner = WinningTeam THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 
        2
    ) AS win_percentage
FROM iplmatches
{where_clause}
"""

st.dataframe(pd.read_sql(query, conn))

# -----------------------------
# 🌟 Player Stats (YOUR QUERIES)
# -----------------------------
st.subheader("🌟 Player Stats")

# Top Player of Match
query = f"""
SELECT Player_of_Match, COUNT(*) AS awards
FROM iplmatches
{where_clause}
GROUP BY Player_of_Match
ORDER BY awards DESC
LIMIT 10
"""
st.write("Top 10 Players")
st.dataframe(pd.read_sql(query, conn))

# -----------------------------
# ⚔️ Batting First vs Chasing
# -----------------------------
st.subheader("⚔️ Batting First vs Chasing")

query = f"""
SELECT WonBy, COUNT(*) AS wins
FROM iplmatches
{where_clause}
GROUP BY WonBy
"""
st.bar_chart(pd.read_sql(query, conn).set_index("WonBy"))

# -----------------------------
# 🏟️ Venue Advantage
# -----------------------------
st.subheader("🏟️ Venue Advantage")

query = f"""
SELECT 
    Venue,
    COUNT(*) AS total_matches,
    SUM(CASE WHEN WonBy = 'Runs' THEN 1 ELSE 0 END) AS batting_first_wins,
    ROUND(
        SUM(CASE WHEN WonBy = 'Runs' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 
        2
    ) AS win_percentage
FROM iplmatches
{where_clause}
GROUP BY Venue
ORDER BY win_percentage DESC
"""
st.dataframe(pd.read_sql(query, conn))

# -----------------------------
# 🏙️ Matches by City
# -----------------------------
st.subheader("🏙️ Matches by City")

query = f"""
SELECT City, COUNT(*) AS total_matches
FROM iplmatches
{where_clause}
GROUP BY City
ORDER BY total_matches DESC
"""
st.bar_chart(pd.read_sql(query, conn).set_index("City"))

# -----------------------------
# 👨‍⚖️ Umpires (YOUR UNION ALL)
# -----------------------------
st.subheader("👨‍⚖️ Top Umpires")

query = f"""
SELECT umpire, COUNT(*) AS matches_officiated
FROM (
    SELECT Umpire1 AS umpire FROM iplmatches {where_clause}
    UNION ALL
    SELECT Umpire2 FROM iplmatches {where_clause}
) u
GROUP BY umpire
ORDER BY matches_officiated DESC
LIMIT 10
"""
st.dataframe(pd.read_sql(query, conn))
