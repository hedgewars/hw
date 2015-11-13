{-
    Glicko2, as described in http://www.glicko.net/glicko/glicko2.pdf
-}

module Main where

--import Data.Map as Map

data RatingData = RatingData {
        ratingValue
        , rD
        , volatility :: Double
    }
data GameData = GameData {
        rating :: RatingData,
        opponentRating :: RatingData,
        gameScore :: Double
    }

τ, ε :: Double
τ = 0.3
ε = 0.000001

g_φ :: Double -> Double
g_φ φ = 1 / sqrt (1 + 3 * φ^2 / pi^2)

calcE :: GameData -> (Double, Double, Double)
calcE (GameData oldRating oppRating s) = (
    1 / (1 + exp (g_φᵢ * (μᵢ - μ)))
    , g_φᵢ
    , s
    )
    where
        μ = (ratingValue oldRating - 1500) / 173.7178
        φ = rD oldRating / 173.7178
        μᵢ = (ratingValue oppRating - 1500) / 173.7178
        φᵢ = rD oppRating / 173.7178
        g_φᵢ = g_φ φᵢ


calcNewRating :: [GameData] -> RatingData
calcNewRating [] = undefined
calcNewRating games@(GameData oldRating _ _ : _) = RatingData (173.7178 * μ' + 1500) (173.7178 * sqrt φ'sqr) σ'
    where
        _Es = map calcE games
        υ = 1 / sum (map υ_p _Es)
        υ_p (_Eᵢ, g_φᵢ, _) = g_φᵢ ^ 2 * _Eᵢ * (1 - _Eᵢ)
        _Δ = υ * part1
        part1 = sum (map _Δ_p _Es)
        _Δ_p (_Eᵢ, g_φᵢ, sᵢ) = g_φᵢ * (sᵢ - _Eᵢ)

        μ = (ratingValue oldRating - 1500) / 173.7178
        φ = rD oldRating / 173.7178
        σ = volatility oldRating

        a = log (σ ^ 2)
        f :: Double -> Double
        f x = exp x * (_Δ ^ 2 - φ ^ 2 - υ - exp x) / 2 / (φ ^ 2 + υ + exp x) ^ 2 - (x - a) / τ ^ 2

        _A = a
        _B = if _Δ ^ 2 > φ ^ 2 + υ then log (_Δ ^ 2 - φ ^ 2 - υ) else head . dropWhile ((>) 0 . f) . map (\k -> a - k * τ) $ [1 ..]
        fA = f _A
        fB = f _B
        σ' = (\(_A, _, _, _) -> exp (_A / 2)) . head . dropWhile (\(_A, _, _B, _) -> abs (_B - _A) > ε) $ iterate step5 (_A, fA, _B, fB)
        step5 (_A, fA, _B, fB) = let _C = _A + (_A - _B) * fA / (fB - fA); fC = f _C in
                                     if fC * fB < 0 then (_B, fB, _C, fC) else (_A, fA / 2, _C, fC)

        φ'sqr = 1 / (1 / (φ ^ 2 + σ' ^ 2) + 1 / υ)
        μ' = μ + φ'sqr * part1

main = undefined
