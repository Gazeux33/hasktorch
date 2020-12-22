{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE AllowAmbiguousTypes #-}
{-# LANGUAGE GeneralizedNewtypeDeriving #-}
{-# LANGUAGE TypeApplications #-}
{-# LANGUAGE DataKinds #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE PolyKinds #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE TypeOperators #-}
{-# LANGUAGE UndecidableInstances #-}
-- {-# OPTIONS_GHC -fplugin TypeLevel.Rewrite
--                 -fplugin-opt=TypeLevel.Rewrite:Torch.GraduallyTyped.Prelude.TestLaw #-}


module Torch.GraduallyTyped.NN.Class where

-- import Control.Monad.State.Strict (MonadState (state), runState)
-- import Torch.GraduallyTyped.Prelude (Contains, ErrorMessage (Text), Fst, If, Proxy (..), Snd, Type, TypeError)
-- import Torch.GraduallyTyped.Random (Generator)
-- import Torch.GraduallyTyped.Device (Device (UncheckedDevice), DeviceType)
-- import Generics.SOP (Code, I, SOP(..), Generic, NS(..), NP)
-- import GHC.Base (coerce, Any)

import Data.Kind (Type)
-- import Torch.GraduallyTyped.Prelude (TestF)

-- class Foo a where
--   foo :: ()

-- f :: forall a b . (Foo (TestF a (TestF a (TestF a (TestF a b))))) => ()
-- f = foo @(TestF a (TestF a b))

-- f' :: forall a b . (Foo (TestF a (TestF a b))) => ()
-- f' = foo @(TestF a b)

-- f'' :: forall a b c. (Foo (TestF a (TestF b c))) => ()
-- f'' = foo @(TestF (TestF a b) c)

-- f''' :: forall a b c. (Foo (TestF (TestF a b) c)) => ()
-- f''' = foo @(TestF a (TestF b c))


class HasForward model input generator where
  type ForwardOutput model input generator :: Type
  type ForwardGeneratorOutput model input generator :: Type
  forward :: model -> input -> generator -> (ForwardOutput model input generator, ForwardGeneratorOutput model input generator)

class HasInitialize model where
  type InitializeF model :: Type
  initialize :: InitializeF model

-- class GHasForward model input where
--   type GOutput model input
--   gForward :: (Generic model, Generic input, Code model ~ Code input) => model -> input -> GOutput model input
--   gForward model input = gForwardSS (from model) (from input)

-- class GHasForwardSS modelss inputss where
--   type GOutputSS modelss inputss
--   gForwardSS :: forall models inputs . (GHasForwardPP models inputs) => SOP I modelss -> SOP I inputss -> GOutputSS modelss inputss
--   gForwardSS (SOP (Z (models :: NP I models))) (SOP (Z (inputs :: NP I inputs))) = gForwardPP @models @inputs models inputs

-- class GHasForwardPP models inputs where
--   type GOutputPP models inputs
--   gForwardPP :: () => NP I models -> NP I inputs -> GOutputPP models inputs

-- data ModelRandomness = Deterministic | Stochastic

-- type family ModelRandomnessR (output :: Type) :: (ModelRandomness, Type) where
--   ModelRandomnessR (Generator device -> (output, Generator device)) =
--     If
--       (Contains output Generator)
--       (TypeError (Text "The random generator appears in a wrong position in the output type."))
--       '( 'Stochastic, output)
--   ModelRandomnessR output =
--     If
--       (Contains output Generator)
--       (TypeError (Text "The random generator appears in a wrong position in the output type."))
--       '( 'Deterministic, output)

-- class
--   HasForwardProduct
--     (modelARandomness :: ModelRandomness)
--     outputA
--     (modelBRandomness :: ModelRandomness)
--     outputB
--     modelA
--     inputA
--     modelB
--     inputB
--   where
--   type
--     ForwardOutputProduct modelARandomness outputA modelBRandomness outputB modelA inputA modelB inputB ::
--       Type
--   forwardProduct ::
--     Proxy modelARandomness ->
--     Proxy outputA ->
--     Proxy modelBRandomness ->
--     Proxy outputB ->
--     (modelA, modelB) ->
--     (inputA, inputB) ->
--     ForwardOutputProduct modelARandomness outputA modelBRandomness outputB modelA inputA modelB inputB

-- instance
--   ( HasForward modelA inputA,
--     ForwardOutput modelA inputA 'UncheckedDevice ~ (Generator 'UncheckedDevice -> (outputA, Generator 'UncheckedDevice)),
--     HasForward modelB inputB,
--     ForwardOutput modelB inputB ~ (Generator 'UncheckedDevice -> (outputB, Generator 'UncheckedDevice))
--   ) =>
--   HasForwardProduct 'Stochastic outputA 'Stochastic outputB modelA inputA modelB inputB
--   where
--   type
--     ForwardOutputProduct 'Stochastic outputA 'Stochastic outputB modelA inputA modelB inputB =
--       Generator 'UncheckedDevice -> ((outputA, outputB), Generator 'UncheckedDevice)
--   forwardProduct _ _ _ _ (modelA, modelB) (inputA, inputB) =
--     runState $ do
--       outputA <- state (forward modelA inputA)
--       outputB <- state (forward modelB inputB)
--       return (outputA, outputB)

-- instance
--   ( '(modelARandomness, outputA) ~ ModelRandomnessR (ForwardOutput modelA inputA),
--     '(modelBRandomness, outputB) ~ ModelRandomnessR (ForwardOutput modelB inputB),
--     HasForwardProduct modelARandomness outputA modelBRandomness outputB modelA inputA modelB inputB
--   ) =>
--   HasForward (modelA, modelB) (inputA, inputB)
--   where
--   type
--     ForwardOutput (modelA, modelB) (inputA, inputB) =
--       ForwardOutputProduct
--         (Fst (ModelRandomnessR (ForwardOutput modelA inputA)))
--         (Snd (ModelRandomnessR (ForwardOutput modelA inputA)))
--         (Fst (ModelRandomnessR (ForwardOutput modelB inputB)))
--         (Snd (ModelRandomnessR (ForwardOutput modelB inputB)))
--         modelA
--         inputA
--         modelB
--         inputB
--   forward =
--     forwardProduct
--       (Proxy :: Proxy modelARandomness)
--       (Proxy :: Proxy outputA)
--       (Proxy :: Proxy modelBRandomness)
--       (Proxy :: Proxy outputB)

-- class
--   HasForwardSum
--     (modelARandomness :: ModelRandomness)
--     outputA
--     (modelBRandomness :: ModelRandomness)
--     outputB
--     modelA
--     inputA
--     modelB
--     inputB
--   where
--   type
--     ForwardOutputSum modelARandomness outputA modelBRandomness outputB modelA inputA modelB inputB ::
--       Type
--   forwardSum ::
--     Proxy modelARandomness ->
--     Proxy outputA ->
--     Proxy modelBRandomness ->
--     Proxy outputB ->
--     Either modelA modelB ->
--     Either inputA inputB ->
--     ForwardOutputSum modelARandomness outputA modelBRandomness outputB modelA inputA modelB inputB

-- instance
--   ( HasForward modelA inputA,
--     ForwardOutput modelA inputA ~ (Generator 'UncheckedDevice -> (outputA, Generator 'UncheckedDevice)),
--     HasForward modelB inputB,
--     ForwardOutput modelB inputB ~ (Generator 'UncheckedDevice -> (outputB, Generator 'UncheckedDevice))
--   ) =>
--   HasForwardSum 'Stochastic outputA 'Stochastic outputB modelA inputA modelB inputB
--   where
--   type
--     ForwardOutputSum 'Stochastic outputA 'Stochastic outputB modelA inputA modelB inputB =
--       Generator 'UncheckedDevice -> (Maybe (Either outputA outputB), Generator 'UncheckedDevice)
--   forwardSum _ _ _ _ (Left modelA) (Left inputA) =
--     runState $ Just . Left <$> (state $ forward modelA inputA)
--   forwardSum _ _ _ _ (Right modelB) (Right inputB) =
--     runState $ Just . Right <$> (state $ forward modelB inputB)
--   forwardSum _ _ _ _ _ _ = runState . pure $ Nothing

-- instance
--   ( '(modelARandomness, outputA) ~ ModelRandomnessR (ForwardOutput modelA inputA),
--     '(modelBRandomness, outputB) ~ ModelRandomnessR (ForwardOutput modelB inputB),
--     HasForwardSum modelARandomness outputA modelBRandomness outputB modelA inputA modelB inputB
--   ) =>
--   HasForward (Either modelA modelB) (Either inputA inputB)
--   where
--   type
--     ForwardOutput (Either modelA modelB) (Either inputA inputB) =
--       ForwardOutputSum
--         (Fst (ModelRandomnessR (ForwardOutput modelA inputA)))
--         (Snd (ModelRandomnessR (ForwardOutput modelA inputA)))
--         (Fst (ModelRandomnessR (ForwardOutput modelB inputB)))
--         (Snd (ModelRandomnessR (ForwardOutput modelB inputB)))
--         modelA
--         inputA
--         modelB
--         inputB
--   forward =
--     forwardSum
--       (Proxy :: Proxy modelARandomness)
--       (Proxy :: Proxy outputA)
--       (Proxy :: Proxy modelBRandomness)
--       (Proxy :: Proxy outputB)

-- data ModelA = ModelA

-- data InputA = InputA

-- data OutputA = OutputA

-- instance HasForward ModelA InputA where
--   type ForwardOutput ModelA InputA = (Generator 'UncheckedDevice -> (OutputA, Generator 'UncheckedDevice))
--   forward _ _ g = (OutputA, g)

-- data ModelB = ModelB

-- data InputB = InputB

-- data OutputB = OutputB

-- instance HasForward ModelB InputB where
--   type ForwardOutput ModelB InputB = (Generator 'UncheckedDevice -> (OutputB, Generator 'UncheckedDevice))
--   forward _ _ g = (OutputB, g)

-- test :: Generator 'UncheckedDevice -> ((OutputA, OutputB), Generator 'UncheckedDevice)
-- test = forward (ModelA, ModelB) (InputA, InputB)

-- test' :: Generator 'UncheckedDevice -> (Maybe (Either OutputA OutputB), Generator 'UncheckedDevice)
-- test' = forward @(Either ModelA ModelB) @(Either InputA InputB) (Left ModelA) (Right InputB)

