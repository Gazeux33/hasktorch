{-# LANGUAGE AllowAmbiguousTypes #-}
{-# LANGUAGE ConstraintKinds #-}
{-# LANGUAGE DataKinds #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE KindSignatures #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE PartialTypeSignatures #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TypeApplications #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE TypeOperators #-}
{-# LANGUAGE UndecidableInstances #-}

module Torch.GraduallyTyped.Tensor.Creation
  ( WithCreateC (..),
    ones,
    checkedOnes,
    uncheckedOnes,
    zeros,
    randn,
    checkedRandn,
    uncheckedRandn,
  )
where

import Data.Int (Int16)
import Data.Kind (Type)
import Data.Monoid (All (..))
import GHC.TypeLits (Nat, Symbol)
import System.IO.Unsafe (unsafePerformIO)
import Torch.DType (DType)
import Torch.GraduallyTyped.DType (DataType (..), KnownDType, WithDataTypeC (..))
import Torch.GraduallyTyped.Device (Device (..), DeviceType, KnownDeviceType, UnifyDeviceC, WithDeviceC (..))
import Torch.GraduallyTyped.Internal.TensorOptions (tensorOptions)
import Torch.GraduallyTyped.Internal.Void (Void)
import Torch.GraduallyTyped.Layout (KnownLayoutType, Layout (..), LayoutType, WithLayoutC (..))
import Torch.GraduallyTyped.Prelude (Catch)
import Torch.GraduallyTyped.Random (Generator, withGenerator)
import Torch.GraduallyTyped.RequiresGradient (KnownRequiresGradient, RequiresGradient (..), requiresGradientVal)
import Torch.GraduallyTyped.Shape (Dim (..), Name (..), Shape (..), Size (..), WithShapeC (..), dimName, dimSize)
import Torch.GraduallyTyped.Tensor.Type (Tensor (..))
import Torch.Internal.Cast (cast2, cast3, cast4)
import qualified Torch.Internal.Managed.TensorFactories as ATen

-- $setup
-- >>> import Data.Int (Int16)
-- >>> import Torch.DType (DType (..))
-- >>> import Torch.GraduallyTyped.Device (DeviceType (..))
-- >>> import Torch.GraduallyTyped.Layout (LayoutType (..))
-- >>> import Torch.GraduallyTyped.RequiresGradient (RequiresGradient (..))
-- >>> import Torch.GraduallyTyped.Shape (Dim (..))

class
  WithCreateC
    (createOut :: Type)
    (requiresGradient :: RequiresGradient)
    (layout :: Layout LayoutType)
    (device :: Device (DeviceType Nat))
    (dataType :: DataType DType)
    (shape :: Shape [Dim (Name Symbol) (Size Nat)])
  where
  type
    WithCreateF createOut requiresGradient layout device dataType shape ::
      Type
  withCreate ::
    ( RequiresGradient ->
      LayoutType ->
      DeviceType Int16 ->
      DType ->
      [Dim String Integer] ->
      createOut
    ) ->
    WithCreateF createOut requiresGradient layout device dataType shape
  withoutCreate ::
    WithCreateF createOut requiresGradient layout device dataType shape ->
    ( RequiresGradient ->
      LayoutType ->
      DeviceType Int16 ->
      DType ->
      [Dim String Integer] ->
      createOut
    )

-- | Auxiliary instance to make 'WithCreateC' opaque.
instance {-# OVERLAPPING #-} WithCreateC Void requiresGradient layout device dataType shape where
  type
    WithCreateF Void requiresGradient layout device dataType shape =
      WithLayoutF
        layout
        ( WithDeviceF
            device
            ( WithDataTypeF
                dataType
                ( WithShapeF
                    shape
                    Void
                )
            )
        )
  withCreate = undefined
  withoutCreate = undefined

-- | Catch-all instance.
instance
  ( KnownRequiresGradient requiresGradient,
    WithLayoutC layout (WithDeviceF device (WithDataTypeF dataType (WithShapeF shape createOut))),
    WithDeviceC device (WithDataTypeF dataType (WithShapeF shape createOut)),
    WithDataTypeC dataType (WithShapeF shape createOut),
    WithShapeC shape createOut
  ) =>
  WithCreateC createOut requiresGradient layout device dataType shape
  where
  type
    WithCreateF createOut requiresGradient layout device dataType shape =
      WithLayoutF
        layout
        ( WithDeviceF
            device
            ( WithDataTypeF
                dataType
                ( WithShapeF
                    shape
                    createOut
                )
            )
        )
  withCreate go =
    withLayout @layout $
      \layoutType ->
        withDevice @device $
          \deviceType ->
            withDataType @dataType $
              \dType ->
                withShape @shape $
                  \shape ->
                    go (requiresGradientVal @requiresGradient) layoutType deviceType dType shape
  withoutCreate go =
    \_requiresGradient layoutType deviceType dType shape ->
      withoutShape @shape
        ( withoutDataType @dataType
            ( withoutDevice @device
                ( withoutLayout @layout
                    go
                    layoutType
                )
                deviceType
            )
            dType
        )
        shape

-- | Create a tensor of ones.
--
-- >>> :type ones @'Dependent @'UncheckedLayout @'UncheckedDevice @'UncheckedDataType @'UncheckedShape
-- ones @'Dependent @'UncheckedLayout @'UncheckedDevice @'UncheckedDataType @'UncheckedShape
--   :: LayoutType
--      -> DeviceType GHC.Int.Int16
--      -> DType
--      -> [Dim String Integer]
--      -> Tensor
--           'Dependent
--           'UncheckedLayout
--           'UncheckedDevice
--           'UncheckedDataType
--           'UncheckedShape
--
-- >>> :type ones @'Dependent @('Layout 'Dense) @'UncheckedDevice @'UncheckedDataType @'UncheckedShape
-- ones @'Dependent @('Layout 'Dense) @'UncheckedDevice @'UncheckedDataType @'UncheckedShape
--   :: DeviceType Int16
--      -> DType
--      -> [Dim String Integer]
--      -> Tensor
--           'Dependent
--           ('Layout 'Dense)
--           'UncheckedDevice
--           'UncheckedDataType
--           'UncheckedShape
--
-- >>> :type ones @'Dependent @('Layout 'Dense) @('Device ('CUDA 0)) @'UncheckedDataType @'UncheckedShape
-- ones @'Dependent @('Layout 'Dense) @('Device ('CUDA 0)) @'UncheckedDataType @'UncheckedShape
--   :: DType
--      -> [Dim String Integer]
--      -> Tensor
--           'Dependent
--           ('Layout 'Dense)
--           ('Device ('CUDA 0))
--           'UncheckedDataType
--           'UncheckedShape
--
-- >>> :type ones @'Dependent @('Layout 'Dense) @('Device ('CUDA 0)) @('DataType 'Half) @'UncheckedShape
-- ones @'Dependent @('Layout 'Dense) @('Device ('CUDA 0)) @('DataType 'Half) @'UncheckedShape
--   :: [Dim String Integer]
--      -> Tensor
--           'Dependent
--           ('Layout 'Dense)
--           ('Device ('CUDA 0))
--           ('DataType 'Half)
--           'UncheckedShape
--
-- >>> :type ones @'Dependent @('Layout 'Dense) @('Device ('CUDA 0)) @('DataType 'Half) @('Shape '[ 'Dim ('Name "batch") ('Size 32), 'Dim ('Name "feature") ('Size 8)])
-- ones @'Dependent @('Layout 'Dense) @('Device ('CUDA 0)) @('DataType 'Half) @('Shape '[ 'Dim ('Name "batch") ('Size 32), 'Dim ('Name "feature") ('Size 8)])
--   :: Tensor
--        'Dependent
--        ('Layout 'Dense)
--        ('Device ('CUDA 0))
--        ('DataType 'Half)
--        ('Shape
--           '[ 'Dim ('Name "batch") ('Size 32),
--              'Dim ('Name "feature") ('Size 8)])
ones ::
  forall requiresGradient layout device dataType shape.
  WithCreateC (Tensor requiresGradient layout device dataType shape) requiresGradient layout device dataType shape =>
  WithCreateF (Tensor requiresGradient layout device dataType shape) requiresGradient layout device dataType shape
ones =
  withCreate
    @(Tensor requiresGradient layout device dataType shape)
    @requiresGradient
    @layout
    @device
    @dataType
    @shape
    go
  where
    go requiresGradient layoutType deviceType dType dims =
      let opts = tensorOptions requiresGradient layoutType deviceType dType
          tensor = unsafePerformIO $ case (map dimName dims, map dimSize dims) of
            (names, sizes)
              | getAll . foldMap (\name -> All $ name == "*") $ names -> cast2 ATen.ones_lo sizes opts
              | otherwise -> cast3 ATen.ones_lNo sizes names opts
       in UnsafeTensor tensor

checkedOnes ::
  forall requiresGradient layoutType deviceType dType dims.
  ( KnownRequiresGradient requiresGradient,
    KnownLayoutType layoutType,
    KnownDeviceType deviceType,
    KnownDType dType,
    WithShapeC ( 'Shape dims) (Tensor requiresGradient ( 'Layout layoutType) ( 'Device deviceType) ( 'DataType dType) ( 'Shape dims))
  ) =>
  WithShapeF
    ( 'Shape dims)
    ( Tensor
        requiresGradient
        ( 'Layout layoutType)
        ( 'Device deviceType)
        ( 'DataType dType)
        ( 'Shape dims)
    )
checkedOnes = ones @requiresGradient @( 'Layout layoutType) @( 'Device deviceType) @( 'DataType dType) @( 'Shape dims)

-- | Like 'ones', but specialized to the case in which all arguments are unchecked at compile time.
uncheckedOnes ::
  -- | Memory layout of the tensor.
  LayoutType ->
  -- | Compute device of the tensor.
  DeviceType Int16 ->
  -- | Data type of the tensor.
  DType ->
  -- | Shape of the tensor.
  [Dim String Integer] ->
  -- | Returned tensor.
  Tensor
    'Dependent
    'UncheckedLayout
    'UncheckedDevice
    'UncheckedDataType
    'UncheckedShape
uncheckedOnes = ones @ 'Dependent @ 'UncheckedLayout @ 'UncheckedDevice @ 'UncheckedDataType @ 'UncheckedShape

zeros ::
  forall requiresGradient layout device dataType shape.
  WithCreateC (Tensor requiresGradient layout device dataType shape) requiresGradient layout device dataType shape =>
  WithCreateF (Tensor requiresGradient layout device dataType shape) requiresGradient layout device dataType shape
zeros =
  withCreate
    @(Tensor requiresGradient layout device dataType shape)
    @requiresGradient
    @layout
    @device
    @dataType
    @shape
    go
  where
    go requiresGradient layoutType deviceType dType dims =
      let opts = tensorOptions requiresGradient layoutType deviceType dType
          tensor = unsafePerformIO $ case (map dimName dims, map dimSize dims) of
            (names, sizes)
              | getAll . foldMap (\name -> All $ name == "*") $ names -> cast2 ATen.zeros_lo sizes opts
              | otherwise -> cast3 ATen.zeros_lNo sizes names opts
       in UnsafeTensor tensor

randn ::
  forall requiresGradient layout device dataType shape device'.
  ( UnifyDeviceC device device',
    WithCreateC (Generator device' -> (Tensor requiresGradient layout device dataType shape, Generator device')) requiresGradient layout device dataType shape
  ) =>
  WithCreateF (Generator device' -> (Tensor requiresGradient layout device dataType shape, Generator device')) requiresGradient layout device dataType shape
randn = withCreate @(Generator device' -> (Tensor requiresGradient layout device dataType shape, Generator device')) @requiresGradient @layout @device @dataType @shape go
  where
    go requiresGradient layoutType deviceType dType shape =
      let opts = tensorOptions requiresGradient layoutType deviceType dType
       in withGenerator
            ( \genPtr -> do
                tensor <- case (map dimName shape, map dimSize shape) of
                  (names, sizes)
                    | getAll . foldMap (\name -> All $ name == "*") $ names -> cast3 ATen.randn_lGo sizes genPtr opts
                    | otherwise -> cast4 ATen.randn_lGNo sizes genPtr names opts
                pure $ UnsafeTensor tensor
            )
            ( unsafePerformIO $ do
                tensor <- case (map dimName shape, map dimSize shape) of
                  (names, sizes)
                    | getAll . foldMap (\name -> All $ name == "*") $ names -> cast2 ATen.zeros_lo sizes opts
                    | otherwise -> cast3 ATen.zeros_lNo sizes names opts
                pure $ UnsafeTensor tensor
            )

checkedRandn ::
  forall requiresGradient layoutType deviceType dType dims.
  ( KnownRequiresGradient requiresGradient,
    KnownLayoutType layoutType,
    KnownDeviceType deviceType,
    KnownDType dType,
    Catch deviceType,
    WithShapeC ( 'Shape dims) (Generator ( 'Device deviceType) -> (Tensor requiresGradient ( 'Layout layoutType) ( 'Device deviceType) ( 'DataType dType) ( 'Shape dims), Generator ( 'Device deviceType)))
  ) =>
  ( WithShapeF
      ( 'Shape dims)
      ( Generator ( 'Device deviceType) ->
        ( Tensor
            requiresGradient
            ( 'Layout layoutType)
            ( 'Device deviceType)
            ( 'DataType dType)
            ( 'Shape dims),
          Generator ( 'Device deviceType)
        )
      )
  )
checkedRandn = randn @requiresGradient @( 'Layout layoutType) @( 'Device deviceType) @( 'DataType dType) @( 'Shape dims) @( 'Device deviceType)

uncheckedRandn ::
  LayoutType ->
  DeviceType Int16 ->
  DType ->
  [Dim String Integer] ->
  Generator 'UncheckedDevice ->
  (Tensor 'Dependent 'UncheckedLayout 'UncheckedDevice 'UncheckedDataType 'UncheckedShape, Generator 'UncheckedDevice)
uncheckedRandn = randn @ 'Dependent @ 'UncheckedLayout @ 'UncheckedDevice @ 'UncheckedDataType @ 'UncheckedShape
