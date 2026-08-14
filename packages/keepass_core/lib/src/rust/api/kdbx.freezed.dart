// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'kdbx.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$CustomDataValue {

 Object get field0;



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CustomDataValue&&const DeepCollectionEquality().equals(other.field0, field0));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(field0));

@override
String toString() {
  return 'CustomDataValue(field0: $field0)';
}


}

/// @nodoc
class $CustomDataValueCopyWith<$Res>  {
$CustomDataValueCopyWith(CustomDataValue _, $Res Function(CustomDataValue) __);
}


/// Adds pattern-matching-related methods to [CustomDataValue].
extension CustomDataValuePatterns on CustomDataValue {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( CustomDataValue_String value)?  string,TResult Function( CustomDataValue_Binary value)?  binary,required TResult orElse(),}){
final _that = this;
switch (_that) {
case CustomDataValue_String() when string != null:
return string(_that);case CustomDataValue_Binary() when binary != null:
return binary(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( CustomDataValue_String value)  string,required TResult Function( CustomDataValue_Binary value)  binary,}){
final _that = this;
switch (_that) {
case CustomDataValue_String():
return string(_that);case CustomDataValue_Binary():
return binary(_that);}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( CustomDataValue_String value)?  string,TResult? Function( CustomDataValue_Binary value)?  binary,}){
final _that = this;
switch (_that) {
case CustomDataValue_String() when string != null:
return string(_that);case CustomDataValue_Binary() when binary != null:
return binary(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String field0)?  string,TResult Function( Uint8List field0)?  binary,required TResult orElse(),}) {final _that = this;
switch (_that) {
case CustomDataValue_String() when string != null:
return string(_that.field0);case CustomDataValue_Binary() when binary != null:
return binary(_that.field0);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String field0)  string,required TResult Function( Uint8List field0)  binary,}) {final _that = this;
switch (_that) {
case CustomDataValue_String():
return string(_that.field0);case CustomDataValue_Binary():
return binary(_that.field0);}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String field0)?  string,TResult? Function( Uint8List field0)?  binary,}) {final _that = this;
switch (_that) {
case CustomDataValue_String() when string != null:
return string(_that.field0);case CustomDataValue_Binary() when binary != null:
return binary(_that.field0);case _:
  return null;

}
}

}

/// @nodoc


class CustomDataValue_String extends CustomDataValue {
  const CustomDataValue_String(this.field0): super._();
  

@override final  String field0;

/// Create a copy of CustomDataValue
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CustomDataValue_StringCopyWith<CustomDataValue_String> get copyWith => _$CustomDataValue_StringCopyWithImpl<CustomDataValue_String>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CustomDataValue_String&&(identical(other.field0, field0) || other.field0 == field0));
}


@override
int get hashCode => Object.hash(runtimeType,field0);

@override
String toString() {
  return 'CustomDataValue.string(field0: $field0)';
}


}

/// @nodoc
abstract mixin class $CustomDataValue_StringCopyWith<$Res> implements $CustomDataValueCopyWith<$Res> {
  factory $CustomDataValue_StringCopyWith(CustomDataValue_String value, $Res Function(CustomDataValue_String) _then) = _$CustomDataValue_StringCopyWithImpl;
@useResult
$Res call({
 String field0
});




}
/// @nodoc
class _$CustomDataValue_StringCopyWithImpl<$Res>
    implements $CustomDataValue_StringCopyWith<$Res> {
  _$CustomDataValue_StringCopyWithImpl(this._self, this._then);

  final CustomDataValue_String _self;
  final $Res Function(CustomDataValue_String) _then;

/// Create a copy of CustomDataValue
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? field0 = null,}) {
  return _then(CustomDataValue_String(
null == field0 ? _self.field0 : field0 // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class CustomDataValue_Binary extends CustomDataValue {
  const CustomDataValue_Binary(this.field0): super._();
  

@override final  Uint8List field0;

/// Create a copy of CustomDataValue
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CustomDataValue_BinaryCopyWith<CustomDataValue_Binary> get copyWith => _$CustomDataValue_BinaryCopyWithImpl<CustomDataValue_Binary>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CustomDataValue_Binary&&const DeepCollectionEquality().equals(other.field0, field0));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(field0));

@override
String toString() {
  return 'CustomDataValue.binary(field0: $field0)';
}


}

/// @nodoc
abstract mixin class $CustomDataValue_BinaryCopyWith<$Res> implements $CustomDataValueCopyWith<$Res> {
  factory $CustomDataValue_BinaryCopyWith(CustomDataValue_Binary value, $Res Function(CustomDataValue_Binary) _then) = _$CustomDataValue_BinaryCopyWithImpl;
@useResult
$Res call({
 Uint8List field0
});




}
/// @nodoc
class _$CustomDataValue_BinaryCopyWithImpl<$Res>
    implements $CustomDataValue_BinaryCopyWith<$Res> {
  _$CustomDataValue_BinaryCopyWithImpl(this._self, this._then);

  final CustomDataValue_Binary _self;
  final $Res Function(CustomDataValue_Binary) _then;

/// Create a copy of CustomDataValue
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? field0 = null,}) {
  return _then(CustomDataValue_Binary(
null == field0 ? _self.field0 : field0 // ignore: cast_nullable_to_non_nullable
as Uint8List,
  ));
}


}

/// @nodoc
mixin _$KdbxAction {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is KdbxAction);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'KdbxAction()';
}


}

/// @nodoc
class $KdbxActionCopyWith<$Res>  {
$KdbxActionCopyWith(KdbxAction _, $Res Function(KdbxAction) __);
}


/// Adds pattern-matching-related methods to [KdbxAction].
extension KdbxActionPatterns on KdbxAction {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( KdbxAction_UpdateEntry value)?  updateEntry,TResult Function( KdbxAction_UpdateGroup value)?  updateGroup,TResult Function( KdbxAction_UpdateMeta value)?  updateMeta,TResult Function( KdbxAction_UpdateMetaCustomData value)?  updateMetaCustomData,TResult Function( KdbxAction_UpdateConfig value)?  updateConfig,TResult Function( KdbxAction_Move2Trash value)?  move2Trash,TResult Function( KdbxAction_Delete value)?  delete,TResult Function( KdbxAction_Restore value)?  restore,TResult Function( KdbxAction_Move2Group value)?  move2Group,TResult Function( KdbxAction_ImportEntry value)?  importEntry,TResult Function( KdbxAction_UpdateSyncEntry value)?  updateSyncEntry,required TResult orElse(),}){
final _that = this;
switch (_that) {
case KdbxAction_UpdateEntry() when updateEntry != null:
return updateEntry(_that);case KdbxAction_UpdateGroup() when updateGroup != null:
return updateGroup(_that);case KdbxAction_UpdateMeta() when updateMeta != null:
return updateMeta(_that);case KdbxAction_UpdateMetaCustomData() when updateMetaCustomData != null:
return updateMetaCustomData(_that);case KdbxAction_UpdateConfig() when updateConfig != null:
return updateConfig(_that);case KdbxAction_Move2Trash() when move2Trash != null:
return move2Trash(_that);case KdbxAction_Delete() when delete != null:
return delete(_that);case KdbxAction_Restore() when restore != null:
return restore(_that);case KdbxAction_Move2Group() when move2Group != null:
return move2Group(_that);case KdbxAction_ImportEntry() when importEntry != null:
return importEntry(_that);case KdbxAction_UpdateSyncEntry() when updateSyncEntry != null:
return updateSyncEntry(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( KdbxAction_UpdateEntry value)  updateEntry,required TResult Function( KdbxAction_UpdateGroup value)  updateGroup,required TResult Function( KdbxAction_UpdateMeta value)  updateMeta,required TResult Function( KdbxAction_UpdateMetaCustomData value)  updateMetaCustomData,required TResult Function( KdbxAction_UpdateConfig value)  updateConfig,required TResult Function( KdbxAction_Move2Trash value)  move2Trash,required TResult Function( KdbxAction_Delete value)  delete,required TResult Function( KdbxAction_Restore value)  restore,required TResult Function( KdbxAction_Move2Group value)  move2Group,required TResult Function( KdbxAction_ImportEntry value)  importEntry,required TResult Function( KdbxAction_UpdateSyncEntry value)  updateSyncEntry,}){
final _that = this;
switch (_that) {
case KdbxAction_UpdateEntry():
return updateEntry(_that);case KdbxAction_UpdateGroup():
return updateGroup(_that);case KdbxAction_UpdateMeta():
return updateMeta(_that);case KdbxAction_UpdateMetaCustomData():
return updateMetaCustomData(_that);case KdbxAction_UpdateConfig():
return updateConfig(_that);case KdbxAction_Move2Trash():
return move2Trash(_that);case KdbxAction_Delete():
return delete(_that);case KdbxAction_Restore():
return restore(_that);case KdbxAction_Move2Group():
return move2Group(_that);case KdbxAction_ImportEntry():
return importEntry(_that);case KdbxAction_UpdateSyncEntry():
return updateSyncEntry(_that);}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( KdbxAction_UpdateEntry value)?  updateEntry,TResult? Function( KdbxAction_UpdateGroup value)?  updateGroup,TResult? Function( KdbxAction_UpdateMeta value)?  updateMeta,TResult? Function( KdbxAction_UpdateMetaCustomData value)?  updateMetaCustomData,TResult? Function( KdbxAction_UpdateConfig value)?  updateConfig,TResult? Function( KdbxAction_Move2Trash value)?  move2Trash,TResult? Function( KdbxAction_Delete value)?  delete,TResult? Function( KdbxAction_Restore value)?  restore,TResult? Function( KdbxAction_Move2Group value)?  move2Group,TResult? Function( KdbxAction_ImportEntry value)?  importEntry,TResult? Function( KdbxAction_UpdateSyncEntry value)?  updateSyncEntry,}){
final _that = this;
switch (_that) {
case KdbxAction_UpdateEntry() when updateEntry != null:
return updateEntry(_that);case KdbxAction_UpdateGroup() when updateGroup != null:
return updateGroup(_that);case KdbxAction_UpdateMeta() when updateMeta != null:
return updateMeta(_that);case KdbxAction_UpdateMetaCustomData() when updateMetaCustomData != null:
return updateMetaCustomData(_that);case KdbxAction_UpdateConfig() when updateConfig != null:
return updateConfig(_that);case KdbxAction_Move2Trash() when move2Trash != null:
return move2Trash(_that);case KdbxAction_Delete() when delete != null:
return delete(_that);case KdbxAction_Restore() when restore != null:
return restore(_that);case KdbxAction_Move2Group() when move2Group != null:
return move2Group(_that);case KdbxAction_ImportEntry() when importEntry != null:
return importEntry(_that);case KdbxAction_UpdateSyncEntry() when updateSyncEntry != null:
return updateSyncEntry(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( EntryData field0)?  updateEntry,TResult Function( GroupData field0)?  updateGroup,TResult Function( String? databaseName,  String? databaseDescription,  PlatformInt64? maintenanceHistoryDays,  Color? color,  PlatformInt64? historyMaxItems,  PlatformInt64? historyMaxSize)?  updateMeta,TResult Function( Map<String, CustomDataValue?> field0)?  updateMetaCustomData,TResult Function( OuterCipherConfig? outerCipherConfig,  CompressionConfig? compressionConfig,  InnerCipherConfig? innerCipherConfig,  KdfConfig? kdfConfig)?  updateConfig,TResult Function( List<String> field0)?  move2Trash,TResult Function( List<String> field0)?  delete,TResult Function( List<String> field0)?  restore,TResult Function( List<String> from,  String to)?  move2Group,TResult Function( List<Map<String, String>> items,  String? to)?  importEntry,TResult Function( EntryData? field0)?  updateSyncEntry,required TResult orElse(),}) {final _that = this;
switch (_that) {
case KdbxAction_UpdateEntry() when updateEntry != null:
return updateEntry(_that.field0);case KdbxAction_UpdateGroup() when updateGroup != null:
return updateGroup(_that.field0);case KdbxAction_UpdateMeta() when updateMeta != null:
return updateMeta(_that.databaseName,_that.databaseDescription,_that.maintenanceHistoryDays,_that.color,_that.historyMaxItems,_that.historyMaxSize);case KdbxAction_UpdateMetaCustomData() when updateMetaCustomData != null:
return updateMetaCustomData(_that.field0);case KdbxAction_UpdateConfig() when updateConfig != null:
return updateConfig(_that.outerCipherConfig,_that.compressionConfig,_that.innerCipherConfig,_that.kdfConfig);case KdbxAction_Move2Trash() when move2Trash != null:
return move2Trash(_that.field0);case KdbxAction_Delete() when delete != null:
return delete(_that.field0);case KdbxAction_Restore() when restore != null:
return restore(_that.field0);case KdbxAction_Move2Group() when move2Group != null:
return move2Group(_that.from,_that.to);case KdbxAction_ImportEntry() when importEntry != null:
return importEntry(_that.items,_that.to);case KdbxAction_UpdateSyncEntry() when updateSyncEntry != null:
return updateSyncEntry(_that.field0);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( EntryData field0)  updateEntry,required TResult Function( GroupData field0)  updateGroup,required TResult Function( String? databaseName,  String? databaseDescription,  PlatformInt64? maintenanceHistoryDays,  Color? color,  PlatformInt64? historyMaxItems,  PlatformInt64? historyMaxSize)  updateMeta,required TResult Function( Map<String, CustomDataValue?> field0)  updateMetaCustomData,required TResult Function( OuterCipherConfig? outerCipherConfig,  CompressionConfig? compressionConfig,  InnerCipherConfig? innerCipherConfig,  KdfConfig? kdfConfig)  updateConfig,required TResult Function( List<String> field0)  move2Trash,required TResult Function( List<String> field0)  delete,required TResult Function( List<String> field0)  restore,required TResult Function( List<String> from,  String to)  move2Group,required TResult Function( List<Map<String, String>> items,  String? to)  importEntry,required TResult Function( EntryData? field0)  updateSyncEntry,}) {final _that = this;
switch (_that) {
case KdbxAction_UpdateEntry():
return updateEntry(_that.field0);case KdbxAction_UpdateGroup():
return updateGroup(_that.field0);case KdbxAction_UpdateMeta():
return updateMeta(_that.databaseName,_that.databaseDescription,_that.maintenanceHistoryDays,_that.color,_that.historyMaxItems,_that.historyMaxSize);case KdbxAction_UpdateMetaCustomData():
return updateMetaCustomData(_that.field0);case KdbxAction_UpdateConfig():
return updateConfig(_that.outerCipherConfig,_that.compressionConfig,_that.innerCipherConfig,_that.kdfConfig);case KdbxAction_Move2Trash():
return move2Trash(_that.field0);case KdbxAction_Delete():
return delete(_that.field0);case KdbxAction_Restore():
return restore(_that.field0);case KdbxAction_Move2Group():
return move2Group(_that.from,_that.to);case KdbxAction_ImportEntry():
return importEntry(_that.items,_that.to);case KdbxAction_UpdateSyncEntry():
return updateSyncEntry(_that.field0);}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( EntryData field0)?  updateEntry,TResult? Function( GroupData field0)?  updateGroup,TResult? Function( String? databaseName,  String? databaseDescription,  PlatformInt64? maintenanceHistoryDays,  Color? color,  PlatformInt64? historyMaxItems,  PlatformInt64? historyMaxSize)?  updateMeta,TResult? Function( Map<String, CustomDataValue?> field0)?  updateMetaCustomData,TResult? Function( OuterCipherConfig? outerCipherConfig,  CompressionConfig? compressionConfig,  InnerCipherConfig? innerCipherConfig,  KdfConfig? kdfConfig)?  updateConfig,TResult? Function( List<String> field0)?  move2Trash,TResult? Function( List<String> field0)?  delete,TResult? Function( List<String> field0)?  restore,TResult? Function( List<String> from,  String to)?  move2Group,TResult? Function( List<Map<String, String>> items,  String? to)?  importEntry,TResult? Function( EntryData? field0)?  updateSyncEntry,}) {final _that = this;
switch (_that) {
case KdbxAction_UpdateEntry() when updateEntry != null:
return updateEntry(_that.field0);case KdbxAction_UpdateGroup() when updateGroup != null:
return updateGroup(_that.field0);case KdbxAction_UpdateMeta() when updateMeta != null:
return updateMeta(_that.databaseName,_that.databaseDescription,_that.maintenanceHistoryDays,_that.color,_that.historyMaxItems,_that.historyMaxSize);case KdbxAction_UpdateMetaCustomData() when updateMetaCustomData != null:
return updateMetaCustomData(_that.field0);case KdbxAction_UpdateConfig() when updateConfig != null:
return updateConfig(_that.outerCipherConfig,_that.compressionConfig,_that.innerCipherConfig,_that.kdfConfig);case KdbxAction_Move2Trash() when move2Trash != null:
return move2Trash(_that.field0);case KdbxAction_Delete() when delete != null:
return delete(_that.field0);case KdbxAction_Restore() when restore != null:
return restore(_that.field0);case KdbxAction_Move2Group() when move2Group != null:
return move2Group(_that.from,_that.to);case KdbxAction_ImportEntry() when importEntry != null:
return importEntry(_that.items,_that.to);case KdbxAction_UpdateSyncEntry() when updateSyncEntry != null:
return updateSyncEntry(_that.field0);case _:
  return null;

}
}

}

/// @nodoc


class KdbxAction_UpdateEntry extends KdbxAction {
  const KdbxAction_UpdateEntry(this.field0): super._();
  

 final  EntryData field0;

/// Create a copy of KdbxAction
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$KdbxAction_UpdateEntryCopyWith<KdbxAction_UpdateEntry> get copyWith => _$KdbxAction_UpdateEntryCopyWithImpl<KdbxAction_UpdateEntry>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is KdbxAction_UpdateEntry&&(identical(other.field0, field0) || other.field0 == field0));
}


@override
int get hashCode => Object.hash(runtimeType,field0);

@override
String toString() {
  return 'KdbxAction.updateEntry(field0: $field0)';
}


}

/// @nodoc
abstract mixin class $KdbxAction_UpdateEntryCopyWith<$Res> implements $KdbxActionCopyWith<$Res> {
  factory $KdbxAction_UpdateEntryCopyWith(KdbxAction_UpdateEntry value, $Res Function(KdbxAction_UpdateEntry) _then) = _$KdbxAction_UpdateEntryCopyWithImpl;
@useResult
$Res call({
 EntryData field0
});




}
/// @nodoc
class _$KdbxAction_UpdateEntryCopyWithImpl<$Res>
    implements $KdbxAction_UpdateEntryCopyWith<$Res> {
  _$KdbxAction_UpdateEntryCopyWithImpl(this._self, this._then);

  final KdbxAction_UpdateEntry _self;
  final $Res Function(KdbxAction_UpdateEntry) _then;

/// Create a copy of KdbxAction
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? field0 = null,}) {
  return _then(KdbxAction_UpdateEntry(
null == field0 ? _self.field0 : field0 // ignore: cast_nullable_to_non_nullable
as EntryData,
  ));
}


}

/// @nodoc


class KdbxAction_UpdateGroup extends KdbxAction {
  const KdbxAction_UpdateGroup(this.field0): super._();
  

 final  GroupData field0;

/// Create a copy of KdbxAction
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$KdbxAction_UpdateGroupCopyWith<KdbxAction_UpdateGroup> get copyWith => _$KdbxAction_UpdateGroupCopyWithImpl<KdbxAction_UpdateGroup>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is KdbxAction_UpdateGroup&&(identical(other.field0, field0) || other.field0 == field0));
}


@override
int get hashCode => Object.hash(runtimeType,field0);

@override
String toString() {
  return 'KdbxAction.updateGroup(field0: $field0)';
}


}

/// @nodoc
abstract mixin class $KdbxAction_UpdateGroupCopyWith<$Res> implements $KdbxActionCopyWith<$Res> {
  factory $KdbxAction_UpdateGroupCopyWith(KdbxAction_UpdateGroup value, $Res Function(KdbxAction_UpdateGroup) _then) = _$KdbxAction_UpdateGroupCopyWithImpl;
@useResult
$Res call({
 GroupData field0
});




}
/// @nodoc
class _$KdbxAction_UpdateGroupCopyWithImpl<$Res>
    implements $KdbxAction_UpdateGroupCopyWith<$Res> {
  _$KdbxAction_UpdateGroupCopyWithImpl(this._self, this._then);

  final KdbxAction_UpdateGroup _self;
  final $Res Function(KdbxAction_UpdateGroup) _then;

/// Create a copy of KdbxAction
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? field0 = null,}) {
  return _then(KdbxAction_UpdateGroup(
null == field0 ? _self.field0 : field0 // ignore: cast_nullable_to_non_nullable
as GroupData,
  ));
}


}

/// @nodoc


class KdbxAction_UpdateMeta extends KdbxAction {
  const KdbxAction_UpdateMeta({this.databaseName, this.databaseDescription, this.maintenanceHistoryDays, this.color, this.historyMaxItems, this.historyMaxSize}): super._();
  

 final  String? databaseName;
 final  String? databaseDescription;
 final  PlatformInt64? maintenanceHistoryDays;
 final  Color? color;
 final  PlatformInt64? historyMaxItems;
 final  PlatformInt64? historyMaxSize;

/// Create a copy of KdbxAction
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$KdbxAction_UpdateMetaCopyWith<KdbxAction_UpdateMeta> get copyWith => _$KdbxAction_UpdateMetaCopyWithImpl<KdbxAction_UpdateMeta>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is KdbxAction_UpdateMeta&&(identical(other.databaseName, databaseName) || other.databaseName == databaseName)&&(identical(other.databaseDescription, databaseDescription) || other.databaseDescription == databaseDescription)&&(identical(other.maintenanceHistoryDays, maintenanceHistoryDays) || other.maintenanceHistoryDays == maintenanceHistoryDays)&&(identical(other.color, color) || other.color == color)&&(identical(other.historyMaxItems, historyMaxItems) || other.historyMaxItems == historyMaxItems)&&(identical(other.historyMaxSize, historyMaxSize) || other.historyMaxSize == historyMaxSize));
}


@override
int get hashCode => Object.hash(runtimeType,databaseName,databaseDescription,maintenanceHistoryDays,color,historyMaxItems,historyMaxSize);

@override
String toString() {
  return 'KdbxAction.updateMeta(databaseName: $databaseName, databaseDescription: $databaseDescription, maintenanceHistoryDays: $maintenanceHistoryDays, color: $color, historyMaxItems: $historyMaxItems, historyMaxSize: $historyMaxSize)';
}


}

/// @nodoc
abstract mixin class $KdbxAction_UpdateMetaCopyWith<$Res> implements $KdbxActionCopyWith<$Res> {
  factory $KdbxAction_UpdateMetaCopyWith(KdbxAction_UpdateMeta value, $Res Function(KdbxAction_UpdateMeta) _then) = _$KdbxAction_UpdateMetaCopyWithImpl;
@useResult
$Res call({
 String? databaseName, String? databaseDescription, PlatformInt64? maintenanceHistoryDays, Color? color, PlatformInt64? historyMaxItems, PlatformInt64? historyMaxSize
});




}
/// @nodoc
class _$KdbxAction_UpdateMetaCopyWithImpl<$Res>
    implements $KdbxAction_UpdateMetaCopyWith<$Res> {
  _$KdbxAction_UpdateMetaCopyWithImpl(this._self, this._then);

  final KdbxAction_UpdateMeta _self;
  final $Res Function(KdbxAction_UpdateMeta) _then;

/// Create a copy of KdbxAction
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? databaseName = freezed,Object? databaseDescription = freezed,Object? maintenanceHistoryDays = freezed,Object? color = freezed,Object? historyMaxItems = freezed,Object? historyMaxSize = freezed,}) {
  return _then(KdbxAction_UpdateMeta(
databaseName: freezed == databaseName ? _self.databaseName : databaseName // ignore: cast_nullable_to_non_nullable
as String?,databaseDescription: freezed == databaseDescription ? _self.databaseDescription : databaseDescription // ignore: cast_nullable_to_non_nullable
as String?,maintenanceHistoryDays: freezed == maintenanceHistoryDays ? _self.maintenanceHistoryDays : maintenanceHistoryDays // ignore: cast_nullable_to_non_nullable
as PlatformInt64?,color: freezed == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as Color?,historyMaxItems: freezed == historyMaxItems ? _self.historyMaxItems : historyMaxItems // ignore: cast_nullable_to_non_nullable
as PlatformInt64?,historyMaxSize: freezed == historyMaxSize ? _self.historyMaxSize : historyMaxSize // ignore: cast_nullable_to_non_nullable
as PlatformInt64?,
  ));
}


}

/// @nodoc


class KdbxAction_UpdateMetaCustomData extends KdbxAction {
  const KdbxAction_UpdateMetaCustomData(final  Map<String, CustomDataValue?> field0): _field0 = field0,super._();
  

 final  Map<String, CustomDataValue?> _field0;
 Map<String, CustomDataValue?> get field0 {
  if (_field0 is EqualUnmodifiableMapView) return _field0;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_field0);
}


/// Create a copy of KdbxAction
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$KdbxAction_UpdateMetaCustomDataCopyWith<KdbxAction_UpdateMetaCustomData> get copyWith => _$KdbxAction_UpdateMetaCustomDataCopyWithImpl<KdbxAction_UpdateMetaCustomData>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is KdbxAction_UpdateMetaCustomData&&const DeepCollectionEquality().equals(other._field0, _field0));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_field0));

@override
String toString() {
  return 'KdbxAction.updateMetaCustomData(field0: $field0)';
}


}

/// @nodoc
abstract mixin class $KdbxAction_UpdateMetaCustomDataCopyWith<$Res> implements $KdbxActionCopyWith<$Res> {
  factory $KdbxAction_UpdateMetaCustomDataCopyWith(KdbxAction_UpdateMetaCustomData value, $Res Function(KdbxAction_UpdateMetaCustomData) _then) = _$KdbxAction_UpdateMetaCustomDataCopyWithImpl;
@useResult
$Res call({
 Map<String, CustomDataValue?> field0
});




}
/// @nodoc
class _$KdbxAction_UpdateMetaCustomDataCopyWithImpl<$Res>
    implements $KdbxAction_UpdateMetaCustomDataCopyWith<$Res> {
  _$KdbxAction_UpdateMetaCustomDataCopyWithImpl(this._self, this._then);

  final KdbxAction_UpdateMetaCustomData _self;
  final $Res Function(KdbxAction_UpdateMetaCustomData) _then;

/// Create a copy of KdbxAction
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? field0 = null,}) {
  return _then(KdbxAction_UpdateMetaCustomData(
null == field0 ? _self._field0 : field0 // ignore: cast_nullable_to_non_nullable
as Map<String, CustomDataValue?>,
  ));
}


}

/// @nodoc


class KdbxAction_UpdateConfig extends KdbxAction {
  const KdbxAction_UpdateConfig({this.outerCipherConfig, this.compressionConfig, this.innerCipherConfig, this.kdfConfig}): super._();
  

 final  OuterCipherConfig? outerCipherConfig;
 final  CompressionConfig? compressionConfig;
 final  InnerCipherConfig? innerCipherConfig;
 final  KdfConfig? kdfConfig;

/// Create a copy of KdbxAction
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$KdbxAction_UpdateConfigCopyWith<KdbxAction_UpdateConfig> get copyWith => _$KdbxAction_UpdateConfigCopyWithImpl<KdbxAction_UpdateConfig>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is KdbxAction_UpdateConfig&&(identical(other.outerCipherConfig, outerCipherConfig) || other.outerCipherConfig == outerCipherConfig)&&(identical(other.compressionConfig, compressionConfig) || other.compressionConfig == compressionConfig)&&(identical(other.innerCipherConfig, innerCipherConfig) || other.innerCipherConfig == innerCipherConfig)&&(identical(other.kdfConfig, kdfConfig) || other.kdfConfig == kdfConfig));
}


@override
int get hashCode => Object.hash(runtimeType,outerCipherConfig,compressionConfig,innerCipherConfig,kdfConfig);

@override
String toString() {
  return 'KdbxAction.updateConfig(outerCipherConfig: $outerCipherConfig, compressionConfig: $compressionConfig, innerCipherConfig: $innerCipherConfig, kdfConfig: $kdfConfig)';
}


}

/// @nodoc
abstract mixin class $KdbxAction_UpdateConfigCopyWith<$Res> implements $KdbxActionCopyWith<$Res> {
  factory $KdbxAction_UpdateConfigCopyWith(KdbxAction_UpdateConfig value, $Res Function(KdbxAction_UpdateConfig) _then) = _$KdbxAction_UpdateConfigCopyWithImpl;
@useResult
$Res call({
 OuterCipherConfig? outerCipherConfig, CompressionConfig? compressionConfig, InnerCipherConfig? innerCipherConfig, KdfConfig? kdfConfig
});


$KdfConfigCopyWith<$Res>? get kdfConfig;

}
/// @nodoc
class _$KdbxAction_UpdateConfigCopyWithImpl<$Res>
    implements $KdbxAction_UpdateConfigCopyWith<$Res> {
  _$KdbxAction_UpdateConfigCopyWithImpl(this._self, this._then);

  final KdbxAction_UpdateConfig _self;
  final $Res Function(KdbxAction_UpdateConfig) _then;

/// Create a copy of KdbxAction
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? outerCipherConfig = freezed,Object? compressionConfig = freezed,Object? innerCipherConfig = freezed,Object? kdfConfig = freezed,}) {
  return _then(KdbxAction_UpdateConfig(
outerCipherConfig: freezed == outerCipherConfig ? _self.outerCipherConfig : outerCipherConfig // ignore: cast_nullable_to_non_nullable
as OuterCipherConfig?,compressionConfig: freezed == compressionConfig ? _self.compressionConfig : compressionConfig // ignore: cast_nullable_to_non_nullable
as CompressionConfig?,innerCipherConfig: freezed == innerCipherConfig ? _self.innerCipherConfig : innerCipherConfig // ignore: cast_nullable_to_non_nullable
as InnerCipherConfig?,kdfConfig: freezed == kdfConfig ? _self.kdfConfig : kdfConfig // ignore: cast_nullable_to_non_nullable
as KdfConfig?,
  ));
}

/// Create a copy of KdbxAction
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$KdfConfigCopyWith<$Res>? get kdfConfig {
    if (_self.kdfConfig == null) {
    return null;
  }

  return $KdfConfigCopyWith<$Res>(_self.kdfConfig!, (value) {
    return _then(_self.copyWith(kdfConfig: value));
  });
}
}

/// @nodoc


class KdbxAction_Move2Trash extends KdbxAction {
  const KdbxAction_Move2Trash(final  List<String> field0): _field0 = field0,super._();
  

 final  List<String> _field0;
 List<String> get field0 {
  if (_field0 is EqualUnmodifiableListView) return _field0;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_field0);
}


/// Create a copy of KdbxAction
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$KdbxAction_Move2TrashCopyWith<KdbxAction_Move2Trash> get copyWith => _$KdbxAction_Move2TrashCopyWithImpl<KdbxAction_Move2Trash>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is KdbxAction_Move2Trash&&const DeepCollectionEquality().equals(other._field0, _field0));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_field0));

@override
String toString() {
  return 'KdbxAction.move2Trash(field0: $field0)';
}


}

/// @nodoc
abstract mixin class $KdbxAction_Move2TrashCopyWith<$Res> implements $KdbxActionCopyWith<$Res> {
  factory $KdbxAction_Move2TrashCopyWith(KdbxAction_Move2Trash value, $Res Function(KdbxAction_Move2Trash) _then) = _$KdbxAction_Move2TrashCopyWithImpl;
@useResult
$Res call({
 List<String> field0
});




}
/// @nodoc
class _$KdbxAction_Move2TrashCopyWithImpl<$Res>
    implements $KdbxAction_Move2TrashCopyWith<$Res> {
  _$KdbxAction_Move2TrashCopyWithImpl(this._self, this._then);

  final KdbxAction_Move2Trash _self;
  final $Res Function(KdbxAction_Move2Trash) _then;

/// Create a copy of KdbxAction
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? field0 = null,}) {
  return _then(KdbxAction_Move2Trash(
null == field0 ? _self._field0 : field0 // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}

/// @nodoc


class KdbxAction_Delete extends KdbxAction {
  const KdbxAction_Delete(final  List<String> field0): _field0 = field0,super._();
  

 final  List<String> _field0;
 List<String> get field0 {
  if (_field0 is EqualUnmodifiableListView) return _field0;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_field0);
}


/// Create a copy of KdbxAction
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$KdbxAction_DeleteCopyWith<KdbxAction_Delete> get copyWith => _$KdbxAction_DeleteCopyWithImpl<KdbxAction_Delete>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is KdbxAction_Delete&&const DeepCollectionEquality().equals(other._field0, _field0));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_field0));

@override
String toString() {
  return 'KdbxAction.delete(field0: $field0)';
}


}

/// @nodoc
abstract mixin class $KdbxAction_DeleteCopyWith<$Res> implements $KdbxActionCopyWith<$Res> {
  factory $KdbxAction_DeleteCopyWith(KdbxAction_Delete value, $Res Function(KdbxAction_Delete) _then) = _$KdbxAction_DeleteCopyWithImpl;
@useResult
$Res call({
 List<String> field0
});




}
/// @nodoc
class _$KdbxAction_DeleteCopyWithImpl<$Res>
    implements $KdbxAction_DeleteCopyWith<$Res> {
  _$KdbxAction_DeleteCopyWithImpl(this._self, this._then);

  final KdbxAction_Delete _self;
  final $Res Function(KdbxAction_Delete) _then;

/// Create a copy of KdbxAction
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? field0 = null,}) {
  return _then(KdbxAction_Delete(
null == field0 ? _self._field0 : field0 // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}

/// @nodoc


class KdbxAction_Restore extends KdbxAction {
  const KdbxAction_Restore(final  List<String> field0): _field0 = field0,super._();
  

 final  List<String> _field0;
 List<String> get field0 {
  if (_field0 is EqualUnmodifiableListView) return _field0;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_field0);
}


/// Create a copy of KdbxAction
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$KdbxAction_RestoreCopyWith<KdbxAction_Restore> get copyWith => _$KdbxAction_RestoreCopyWithImpl<KdbxAction_Restore>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is KdbxAction_Restore&&const DeepCollectionEquality().equals(other._field0, _field0));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_field0));

@override
String toString() {
  return 'KdbxAction.restore(field0: $field0)';
}


}

/// @nodoc
abstract mixin class $KdbxAction_RestoreCopyWith<$Res> implements $KdbxActionCopyWith<$Res> {
  factory $KdbxAction_RestoreCopyWith(KdbxAction_Restore value, $Res Function(KdbxAction_Restore) _then) = _$KdbxAction_RestoreCopyWithImpl;
@useResult
$Res call({
 List<String> field0
});




}
/// @nodoc
class _$KdbxAction_RestoreCopyWithImpl<$Res>
    implements $KdbxAction_RestoreCopyWith<$Res> {
  _$KdbxAction_RestoreCopyWithImpl(this._self, this._then);

  final KdbxAction_Restore _self;
  final $Res Function(KdbxAction_Restore) _then;

/// Create a copy of KdbxAction
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? field0 = null,}) {
  return _then(KdbxAction_Restore(
null == field0 ? _self._field0 : field0 // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}

/// @nodoc


class KdbxAction_Move2Group extends KdbxAction {
  const KdbxAction_Move2Group({required final  List<String> from, required this.to}): _from = from,super._();
  

 final  List<String> _from;
 List<String> get from {
  if (_from is EqualUnmodifiableListView) return _from;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_from);
}

 final  String to;

/// Create a copy of KdbxAction
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$KdbxAction_Move2GroupCopyWith<KdbxAction_Move2Group> get copyWith => _$KdbxAction_Move2GroupCopyWithImpl<KdbxAction_Move2Group>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is KdbxAction_Move2Group&&const DeepCollectionEquality().equals(other._from, _from)&&(identical(other.to, to) || other.to == to));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_from),to);

@override
String toString() {
  return 'KdbxAction.move2Group(from: $from, to: $to)';
}


}

/// @nodoc
abstract mixin class $KdbxAction_Move2GroupCopyWith<$Res> implements $KdbxActionCopyWith<$Res> {
  factory $KdbxAction_Move2GroupCopyWith(KdbxAction_Move2Group value, $Res Function(KdbxAction_Move2Group) _then) = _$KdbxAction_Move2GroupCopyWithImpl;
@useResult
$Res call({
 List<String> from, String to
});




}
/// @nodoc
class _$KdbxAction_Move2GroupCopyWithImpl<$Res>
    implements $KdbxAction_Move2GroupCopyWith<$Res> {
  _$KdbxAction_Move2GroupCopyWithImpl(this._self, this._then);

  final KdbxAction_Move2Group _self;
  final $Res Function(KdbxAction_Move2Group) _then;

/// Create a copy of KdbxAction
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? from = null,Object? to = null,}) {
  return _then(KdbxAction_Move2Group(
from: null == from ? _self._from : from // ignore: cast_nullable_to_non_nullable
as List<String>,to: null == to ? _self.to : to // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class KdbxAction_ImportEntry extends KdbxAction {
  const KdbxAction_ImportEntry({required final  List<Map<String, String>> items, this.to}): _items = items,super._();
  

 final  List<Map<String, String>> _items;
 List<Map<String, String>> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}

 final  String? to;

/// Create a copy of KdbxAction
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$KdbxAction_ImportEntryCopyWith<KdbxAction_ImportEntry> get copyWith => _$KdbxAction_ImportEntryCopyWithImpl<KdbxAction_ImportEntry>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is KdbxAction_ImportEntry&&const DeepCollectionEquality().equals(other._items, _items)&&(identical(other.to, to) || other.to == to));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_items),to);

@override
String toString() {
  return 'KdbxAction.importEntry(items: $items, to: $to)';
}


}

/// @nodoc
abstract mixin class $KdbxAction_ImportEntryCopyWith<$Res> implements $KdbxActionCopyWith<$Res> {
  factory $KdbxAction_ImportEntryCopyWith(KdbxAction_ImportEntry value, $Res Function(KdbxAction_ImportEntry) _then) = _$KdbxAction_ImportEntryCopyWithImpl;
@useResult
$Res call({
 List<Map<String, String>> items, String? to
});




}
/// @nodoc
class _$KdbxAction_ImportEntryCopyWithImpl<$Res>
    implements $KdbxAction_ImportEntryCopyWith<$Res> {
  _$KdbxAction_ImportEntryCopyWithImpl(this._self, this._then);

  final KdbxAction_ImportEntry _self;
  final $Res Function(KdbxAction_ImportEntry) _then;

/// Create a copy of KdbxAction
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? items = null,Object? to = freezed,}) {
  return _then(KdbxAction_ImportEntry(
items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<Map<String, String>>,to: freezed == to ? _self.to : to // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc


class KdbxAction_UpdateSyncEntry extends KdbxAction {
  const KdbxAction_UpdateSyncEntry([this.field0]): super._();
  

 final  EntryData? field0;

/// Create a copy of KdbxAction
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$KdbxAction_UpdateSyncEntryCopyWith<KdbxAction_UpdateSyncEntry> get copyWith => _$KdbxAction_UpdateSyncEntryCopyWithImpl<KdbxAction_UpdateSyncEntry>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is KdbxAction_UpdateSyncEntry&&(identical(other.field0, field0) || other.field0 == field0));
}


@override
int get hashCode => Object.hash(runtimeType,field0);

@override
String toString() {
  return 'KdbxAction.updateSyncEntry(field0: $field0)';
}


}

/// @nodoc
abstract mixin class $KdbxAction_UpdateSyncEntryCopyWith<$Res> implements $KdbxActionCopyWith<$Res> {
  factory $KdbxAction_UpdateSyncEntryCopyWith(KdbxAction_UpdateSyncEntry value, $Res Function(KdbxAction_UpdateSyncEntry) _then) = _$KdbxAction_UpdateSyncEntryCopyWithImpl;
@useResult
$Res call({
 EntryData? field0
});




}
/// @nodoc
class _$KdbxAction_UpdateSyncEntryCopyWithImpl<$Res>
    implements $KdbxAction_UpdateSyncEntryCopyWith<$Res> {
  _$KdbxAction_UpdateSyncEntryCopyWithImpl(this._self, this._then);

  final KdbxAction_UpdateSyncEntry _self;
  final $Res Function(KdbxAction_UpdateSyncEntry) _then;

/// Create a copy of KdbxAction
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? field0 = freezed,}) {
  return _then(KdbxAction_UpdateSyncEntry(
freezed == field0 ? _self.field0 : field0 // ignore: cast_nullable_to_non_nullable
as EntryData?,
  ));
}


}

/// @nodoc
mixin _$KdbxEvent {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is KdbxEvent);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'KdbxEvent()';
}


}

/// @nodoc
class $KdbxEventCopyWith<$Res>  {
$KdbxEventCopyWith(KdbxEvent _, $Res Function(KdbxEvent) __);
}


/// Adds pattern-matching-related methods to [KdbxEvent].
extension KdbxEventPatterns on KdbxEvent {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( KdbxEvent_Saved value)?  saved,TResult Function( KdbxEvent_None value)?  none,required TResult orElse(),}){
final _that = this;
switch (_that) {
case KdbxEvent_Saved() when saved != null:
return saved(_that);case KdbxEvent_None() when none != null:
return none(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( KdbxEvent_Saved value)  saved,required TResult Function( KdbxEvent_None value)  none,}){
final _that = this;
switch (_that) {
case KdbxEvent_Saved():
return saved(_that);case KdbxEvent_None():
return none(_that);}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( KdbxEvent_Saved value)?  saved,TResult? Function( KdbxEvent_None value)?  none,}){
final _that = this;
switch (_that) {
case KdbxEvent_Saved() when saved != null:
return saved(_that);case KdbxEvent_None() when none != null:
return none(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  saved,TResult Function( String field0)?  none,required TResult orElse(),}) {final _that = this;
switch (_that) {
case KdbxEvent_Saved() when saved != null:
return saved();case KdbxEvent_None() when none != null:
return none(_that.field0);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  saved,required TResult Function( String field0)  none,}) {final _that = this;
switch (_that) {
case KdbxEvent_Saved():
return saved();case KdbxEvent_None():
return none(_that.field0);}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  saved,TResult? Function( String field0)?  none,}) {final _that = this;
switch (_that) {
case KdbxEvent_Saved() when saved != null:
return saved();case KdbxEvent_None() when none != null:
return none(_that.field0);case _:
  return null;

}
}

}

/// @nodoc


class KdbxEvent_Saved extends KdbxEvent {
  const KdbxEvent_Saved(): super._();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is KdbxEvent_Saved);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'KdbxEvent.saved()';
}


}




/// @nodoc


class KdbxEvent_None extends KdbxEvent {
  const KdbxEvent_None(this.field0): super._();
  

 final  String field0;

/// Create a copy of KdbxEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$KdbxEvent_NoneCopyWith<KdbxEvent_None> get copyWith => _$KdbxEvent_NoneCopyWithImpl<KdbxEvent_None>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is KdbxEvent_None&&(identical(other.field0, field0) || other.field0 == field0));
}


@override
int get hashCode => Object.hash(runtimeType,field0);

@override
String toString() {
  return 'KdbxEvent.none(field0: $field0)';
}


}

/// @nodoc
abstract mixin class $KdbxEvent_NoneCopyWith<$Res> implements $KdbxEventCopyWith<$Res> {
  factory $KdbxEvent_NoneCopyWith(KdbxEvent_None value, $Res Function(KdbxEvent_None) _then) = _$KdbxEvent_NoneCopyWithImpl;
@useResult
$Res call({
 String field0
});




}
/// @nodoc
class _$KdbxEvent_NoneCopyWithImpl<$Res>
    implements $KdbxEvent_NoneCopyWith<$Res> {
  _$KdbxEvent_NoneCopyWithImpl(this._self, this._then);

  final KdbxEvent_None _self;
  final $Res Function(KdbxEvent_None) _then;

/// Create a copy of KdbxEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? field0 = null,}) {
  return _then(KdbxEvent_None(
null == field0 ? _self.field0 : field0 // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
mixin _$KdbxIcon {

 Object get field0;



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is KdbxIcon&&const DeepCollectionEquality().equals(other.field0, field0));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(field0));

@override
String toString() {
  return 'KdbxIcon(field0: $field0)';
}


}

/// @nodoc
class $KdbxIconCopyWith<$Res>  {
$KdbxIconCopyWith(KdbxIcon _, $Res Function(KdbxIcon) __);
}


/// Adds pattern-matching-related methods to [KdbxIcon].
extension KdbxIconPatterns on KdbxIcon {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( KdbxIcon_BuiltIn value)?  builtIn,TResult Function( KdbxIcon_Custom value)?  custom,required TResult orElse(),}){
final _that = this;
switch (_that) {
case KdbxIcon_BuiltIn() when builtIn != null:
return builtIn(_that);case KdbxIcon_Custom() when custom != null:
return custom(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( KdbxIcon_BuiltIn value)  builtIn,required TResult Function( KdbxIcon_Custom value)  custom,}){
final _that = this;
switch (_that) {
case KdbxIcon_BuiltIn():
return builtIn(_that);case KdbxIcon_Custom():
return custom(_that);}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( KdbxIcon_BuiltIn value)?  builtIn,TResult? Function( KdbxIcon_Custom value)?  custom,}){
final _that = this;
switch (_that) {
case KdbxIcon_BuiltIn() when builtIn != null:
return builtIn(_that);case KdbxIcon_Custom() when custom != null:
return custom(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( int field0)?  builtIn,TResult Function( String field0,  Uint8List? field1)?  custom,required TResult orElse(),}) {final _that = this;
switch (_that) {
case KdbxIcon_BuiltIn() when builtIn != null:
return builtIn(_that.field0);case KdbxIcon_Custom() when custom != null:
return custom(_that.field0,_that.field1);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( int field0)  builtIn,required TResult Function( String field0,  Uint8List? field1)  custom,}) {final _that = this;
switch (_that) {
case KdbxIcon_BuiltIn():
return builtIn(_that.field0);case KdbxIcon_Custom():
return custom(_that.field0,_that.field1);}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( int field0)?  builtIn,TResult? Function( String field0,  Uint8List? field1)?  custom,}) {final _that = this;
switch (_that) {
case KdbxIcon_BuiltIn() when builtIn != null:
return builtIn(_that.field0);case KdbxIcon_Custom() when custom != null:
return custom(_that.field0,_that.field1);case _:
  return null;

}
}

}

/// @nodoc


class KdbxIcon_BuiltIn extends KdbxIcon {
  const KdbxIcon_BuiltIn(this.field0): super._();
  

@override final  int field0;

/// Create a copy of KdbxIcon
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$KdbxIcon_BuiltInCopyWith<KdbxIcon_BuiltIn> get copyWith => _$KdbxIcon_BuiltInCopyWithImpl<KdbxIcon_BuiltIn>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is KdbxIcon_BuiltIn&&(identical(other.field0, field0) || other.field0 == field0));
}


@override
int get hashCode => Object.hash(runtimeType,field0);

@override
String toString() {
  return 'KdbxIcon.builtIn(field0: $field0)';
}


}

/// @nodoc
abstract mixin class $KdbxIcon_BuiltInCopyWith<$Res> implements $KdbxIconCopyWith<$Res> {
  factory $KdbxIcon_BuiltInCopyWith(KdbxIcon_BuiltIn value, $Res Function(KdbxIcon_BuiltIn) _then) = _$KdbxIcon_BuiltInCopyWithImpl;
@useResult
$Res call({
 int field0
});




}
/// @nodoc
class _$KdbxIcon_BuiltInCopyWithImpl<$Res>
    implements $KdbxIcon_BuiltInCopyWith<$Res> {
  _$KdbxIcon_BuiltInCopyWithImpl(this._self, this._then);

  final KdbxIcon_BuiltIn _self;
  final $Res Function(KdbxIcon_BuiltIn) _then;

/// Create a copy of KdbxIcon
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? field0 = null,}) {
  return _then(KdbxIcon_BuiltIn(
null == field0 ? _self.field0 : field0 // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc


class KdbxIcon_Custom extends KdbxIcon {
  const KdbxIcon_Custom(this.field0, [this.field1]): super._();
  

@override final  String field0;
 final  Uint8List? field1;

/// Create a copy of KdbxIcon
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$KdbxIcon_CustomCopyWith<KdbxIcon_Custom> get copyWith => _$KdbxIcon_CustomCopyWithImpl<KdbxIcon_Custom>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is KdbxIcon_Custom&&(identical(other.field0, field0) || other.field0 == field0)&&const DeepCollectionEquality().equals(other.field1, field1));
}


@override
int get hashCode => Object.hash(runtimeType,field0,const DeepCollectionEquality().hash(field1));

@override
String toString() {
  return 'KdbxIcon.custom(field0: $field0, field1: $field1)';
}


}

/// @nodoc
abstract mixin class $KdbxIcon_CustomCopyWith<$Res> implements $KdbxIconCopyWith<$Res> {
  factory $KdbxIcon_CustomCopyWith(KdbxIcon_Custom value, $Res Function(KdbxIcon_Custom) _then) = _$KdbxIcon_CustomCopyWithImpl;
@useResult
$Res call({
 String field0, Uint8List? field1
});




}
/// @nodoc
class _$KdbxIcon_CustomCopyWithImpl<$Res>
    implements $KdbxIcon_CustomCopyWith<$Res> {
  _$KdbxIcon_CustomCopyWithImpl(this._self, this._then);

  final KdbxIcon_Custom _self;
  final $Res Function(KdbxIcon_Custom) _then;

/// Create a copy of KdbxIcon
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? field0 = null,Object? field1 = freezed,}) {
  return _then(KdbxIcon_Custom(
null == field0 ? _self.field0 : field0 // ignore: cast_nullable_to_non_nullable
as String,freezed == field1 ? _self.field1 : field1 // ignore: cast_nullable_to_non_nullable
as Uint8List?,
  ));
}


}

/// @nodoc
mixin _$KdfConfig {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is KdfConfig);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'KdfConfig()';
}


}

/// @nodoc
class $KdfConfigCopyWith<$Res>  {
$KdfConfigCopyWith(KdfConfig _, $Res Function(KdfConfig) __);
}


/// Adds pattern-matching-related methods to [KdfConfig].
extension KdfConfigPatterns on KdfConfig {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( KdfConfig_Aes value)?  aes,TResult Function( KdfConfig_Argon2 value)?  argon2,TResult Function( KdfConfig_Argon2id value)?  argon2Id,required TResult orElse(),}){
final _that = this;
switch (_that) {
case KdfConfig_Aes() when aes != null:
return aes(_that);case KdfConfig_Argon2() when argon2 != null:
return argon2(_that);case KdfConfig_Argon2id() when argon2Id != null:
return argon2Id(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( KdfConfig_Aes value)  aes,required TResult Function( KdfConfig_Argon2 value)  argon2,required TResult Function( KdfConfig_Argon2id value)  argon2Id,}){
final _that = this;
switch (_that) {
case KdfConfig_Aes():
return aes(_that);case KdfConfig_Argon2():
return argon2(_that);case KdfConfig_Argon2id():
return argon2Id(_that);}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( KdfConfig_Aes value)?  aes,TResult? Function( KdfConfig_Argon2 value)?  argon2,TResult? Function( KdfConfig_Argon2id value)?  argon2Id,}){
final _that = this;
switch (_that) {
case KdfConfig_Aes() when aes != null:
return aes(_that);case KdfConfig_Argon2() when argon2 != null:
return argon2(_that);case KdfConfig_Argon2id() when argon2Id != null:
return argon2Id(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( int rounds)?  aes,TResult Function( int iterations,  int memory,  int parallelism,  Argon2Version version)?  argon2,TResult Function( int iterations,  int memory,  int parallelism,  Argon2Version version)?  argon2Id,required TResult orElse(),}) {final _that = this;
switch (_that) {
case KdfConfig_Aes() when aes != null:
return aes(_that.rounds);case KdfConfig_Argon2() when argon2 != null:
return argon2(_that.iterations,_that.memory,_that.parallelism,_that.version);case KdfConfig_Argon2id() when argon2Id != null:
return argon2Id(_that.iterations,_that.memory,_that.parallelism,_that.version);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( int rounds)  aes,required TResult Function( int iterations,  int memory,  int parallelism,  Argon2Version version)  argon2,required TResult Function( int iterations,  int memory,  int parallelism,  Argon2Version version)  argon2Id,}) {final _that = this;
switch (_that) {
case KdfConfig_Aes():
return aes(_that.rounds);case KdfConfig_Argon2():
return argon2(_that.iterations,_that.memory,_that.parallelism,_that.version);case KdfConfig_Argon2id():
return argon2Id(_that.iterations,_that.memory,_that.parallelism,_that.version);}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( int rounds)?  aes,TResult? Function( int iterations,  int memory,  int parallelism,  Argon2Version version)?  argon2,TResult? Function( int iterations,  int memory,  int parallelism,  Argon2Version version)?  argon2Id,}) {final _that = this;
switch (_that) {
case KdfConfig_Aes() when aes != null:
return aes(_that.rounds);case KdfConfig_Argon2() when argon2 != null:
return argon2(_that.iterations,_that.memory,_that.parallelism,_that.version);case KdfConfig_Argon2id() when argon2Id != null:
return argon2Id(_that.iterations,_that.memory,_that.parallelism,_that.version);case _:
  return null;

}
}

}

/// @nodoc


class KdfConfig_Aes extends KdfConfig {
  const KdfConfig_Aes({required this.rounds}): super._();
  

 final  int rounds;

/// Create a copy of KdfConfig
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$KdfConfig_AesCopyWith<KdfConfig_Aes> get copyWith => _$KdfConfig_AesCopyWithImpl<KdfConfig_Aes>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is KdfConfig_Aes&&(identical(other.rounds, rounds) || other.rounds == rounds));
}


@override
int get hashCode => Object.hash(runtimeType,rounds);

@override
String toString() {
  return 'KdfConfig.aes(rounds: $rounds)';
}


}

/// @nodoc
abstract mixin class $KdfConfig_AesCopyWith<$Res> implements $KdfConfigCopyWith<$Res> {
  factory $KdfConfig_AesCopyWith(KdfConfig_Aes value, $Res Function(KdfConfig_Aes) _then) = _$KdfConfig_AesCopyWithImpl;
@useResult
$Res call({
 int rounds
});




}
/// @nodoc
class _$KdfConfig_AesCopyWithImpl<$Res>
    implements $KdfConfig_AesCopyWith<$Res> {
  _$KdfConfig_AesCopyWithImpl(this._self, this._then);

  final KdfConfig_Aes _self;
  final $Res Function(KdfConfig_Aes) _then;

/// Create a copy of KdfConfig
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? rounds = null,}) {
  return _then(KdfConfig_Aes(
rounds: null == rounds ? _self.rounds : rounds // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc


class KdfConfig_Argon2 extends KdfConfig {
  const KdfConfig_Argon2({required this.iterations, required this.memory, required this.parallelism, required this.version}): super._();
  

 final  int iterations;
 final  int memory;
 final  int parallelism;
 final  Argon2Version version;

/// Create a copy of KdfConfig
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$KdfConfig_Argon2CopyWith<KdfConfig_Argon2> get copyWith => _$KdfConfig_Argon2CopyWithImpl<KdfConfig_Argon2>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is KdfConfig_Argon2&&(identical(other.iterations, iterations) || other.iterations == iterations)&&(identical(other.memory, memory) || other.memory == memory)&&(identical(other.parallelism, parallelism) || other.parallelism == parallelism)&&(identical(other.version, version) || other.version == version));
}


@override
int get hashCode => Object.hash(runtimeType,iterations,memory,parallelism,version);

@override
String toString() {
  return 'KdfConfig.argon2(iterations: $iterations, memory: $memory, parallelism: $parallelism, version: $version)';
}


}

/// @nodoc
abstract mixin class $KdfConfig_Argon2CopyWith<$Res> implements $KdfConfigCopyWith<$Res> {
  factory $KdfConfig_Argon2CopyWith(KdfConfig_Argon2 value, $Res Function(KdfConfig_Argon2) _then) = _$KdfConfig_Argon2CopyWithImpl;
@useResult
$Res call({
 int iterations, int memory, int parallelism, Argon2Version version
});




}
/// @nodoc
class _$KdfConfig_Argon2CopyWithImpl<$Res>
    implements $KdfConfig_Argon2CopyWith<$Res> {
  _$KdfConfig_Argon2CopyWithImpl(this._self, this._then);

  final KdfConfig_Argon2 _self;
  final $Res Function(KdfConfig_Argon2) _then;

/// Create a copy of KdfConfig
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? iterations = null,Object? memory = null,Object? parallelism = null,Object? version = null,}) {
  return _then(KdfConfig_Argon2(
iterations: null == iterations ? _self.iterations : iterations // ignore: cast_nullable_to_non_nullable
as int,memory: null == memory ? _self.memory : memory // ignore: cast_nullable_to_non_nullable
as int,parallelism: null == parallelism ? _self.parallelism : parallelism // ignore: cast_nullable_to_non_nullable
as int,version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as Argon2Version,
  ));
}


}

/// @nodoc


class KdfConfig_Argon2id extends KdfConfig {
  const KdfConfig_Argon2id({required this.iterations, required this.memory, required this.parallelism, required this.version}): super._();
  

 final  int iterations;
 final  int memory;
 final  int parallelism;
 final  Argon2Version version;

/// Create a copy of KdfConfig
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$KdfConfig_Argon2idCopyWith<KdfConfig_Argon2id> get copyWith => _$KdfConfig_Argon2idCopyWithImpl<KdfConfig_Argon2id>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is KdfConfig_Argon2id&&(identical(other.iterations, iterations) || other.iterations == iterations)&&(identical(other.memory, memory) || other.memory == memory)&&(identical(other.parallelism, parallelism) || other.parallelism == parallelism)&&(identical(other.version, version) || other.version == version));
}


@override
int get hashCode => Object.hash(runtimeType,iterations,memory,parallelism,version);

@override
String toString() {
  return 'KdfConfig.argon2Id(iterations: $iterations, memory: $memory, parallelism: $parallelism, version: $version)';
}


}

/// @nodoc
abstract mixin class $KdfConfig_Argon2idCopyWith<$Res> implements $KdfConfigCopyWith<$Res> {
  factory $KdfConfig_Argon2idCopyWith(KdfConfig_Argon2id value, $Res Function(KdfConfig_Argon2id) _then) = _$KdfConfig_Argon2idCopyWithImpl;
@useResult
$Res call({
 int iterations, int memory, int parallelism, Argon2Version version
});




}
/// @nodoc
class _$KdfConfig_Argon2idCopyWithImpl<$Res>
    implements $KdfConfig_Argon2idCopyWith<$Res> {
  _$KdfConfig_Argon2idCopyWithImpl(this._self, this._then);

  final KdfConfig_Argon2id _self;
  final $Res Function(KdfConfig_Argon2id) _then;

/// Create a copy of KdfConfig
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? iterations = null,Object? memory = null,Object? parallelism = null,Object? version = null,}) {
  return _then(KdfConfig_Argon2id(
iterations: null == iterations ? _self.iterations : iterations // ignore: cast_nullable_to_non_nullable
as int,memory: null == memory ? _self.memory : memory // ignore: cast_nullable_to_non_nullable
as int,parallelism: null == parallelism ? _self.parallelism : parallelism // ignore: cast_nullable_to_non_nullable
as int,version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as Argon2Version,
  ));
}


}

/// @nodoc
mixin _$MergeEventTarget {

 String get field0;
/// Create a copy of MergeEventTarget
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MergeEventTargetCopyWith<MergeEventTarget> get copyWith => _$MergeEventTargetCopyWithImpl<MergeEventTarget>(this as MergeEventTarget, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MergeEventTarget&&(identical(other.field0, field0) || other.field0 == field0));
}


@override
int get hashCode => Object.hash(runtimeType,field0);

@override
String toString() {
  return 'MergeEventTarget(field0: $field0)';
}


}

/// @nodoc
abstract mixin class $MergeEventTargetCopyWith<$Res>  {
  factory $MergeEventTargetCopyWith(MergeEventTarget value, $Res Function(MergeEventTarget) _then) = _$MergeEventTargetCopyWithImpl;
@useResult
$Res call({
 String field0
});




}
/// @nodoc
class _$MergeEventTargetCopyWithImpl<$Res>
    implements $MergeEventTargetCopyWith<$Res> {
  _$MergeEventTargetCopyWithImpl(this._self, this._then);

  final MergeEventTarget _self;
  final $Res Function(MergeEventTarget) _then;

/// Create a copy of MergeEventTarget
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? field0 = null,}) {
  return _then(_self.copyWith(
field0: null == field0 ? _self.field0 : field0 // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [MergeEventTarget].
extension MergeEventTargetPatterns on MergeEventTarget {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( MergeEventTarget_Entry value)?  entry,TResult Function( MergeEventTarget_Group value)?  group,TResult Function( MergeEventTarget_Icon value)?  icon,required TResult orElse(),}){
final _that = this;
switch (_that) {
case MergeEventTarget_Entry() when entry != null:
return entry(_that);case MergeEventTarget_Group() when group != null:
return group(_that);case MergeEventTarget_Icon() when icon != null:
return icon(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( MergeEventTarget_Entry value)  entry,required TResult Function( MergeEventTarget_Group value)  group,required TResult Function( MergeEventTarget_Icon value)  icon,}){
final _that = this;
switch (_that) {
case MergeEventTarget_Entry():
return entry(_that);case MergeEventTarget_Group():
return group(_that);case MergeEventTarget_Icon():
return icon(_that);}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( MergeEventTarget_Entry value)?  entry,TResult? Function( MergeEventTarget_Group value)?  group,TResult? Function( MergeEventTarget_Icon value)?  icon,}){
final _that = this;
switch (_that) {
case MergeEventTarget_Entry() when entry != null:
return entry(_that);case MergeEventTarget_Group() when group != null:
return group(_that);case MergeEventTarget_Icon() when icon != null:
return icon(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String field0)?  entry,TResult Function( String field0)?  group,TResult Function( String field0)?  icon,required TResult orElse(),}) {final _that = this;
switch (_that) {
case MergeEventTarget_Entry() when entry != null:
return entry(_that.field0);case MergeEventTarget_Group() when group != null:
return group(_that.field0);case MergeEventTarget_Icon() when icon != null:
return icon(_that.field0);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String field0)  entry,required TResult Function( String field0)  group,required TResult Function( String field0)  icon,}) {final _that = this;
switch (_that) {
case MergeEventTarget_Entry():
return entry(_that.field0);case MergeEventTarget_Group():
return group(_that.field0);case MergeEventTarget_Icon():
return icon(_that.field0);}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String field0)?  entry,TResult? Function( String field0)?  group,TResult? Function( String field0)?  icon,}) {final _that = this;
switch (_that) {
case MergeEventTarget_Entry() when entry != null:
return entry(_that.field0);case MergeEventTarget_Group() when group != null:
return group(_that.field0);case MergeEventTarget_Icon() when icon != null:
return icon(_that.field0);case _:
  return null;

}
}

}

/// @nodoc


class MergeEventTarget_Entry extends MergeEventTarget {
  const MergeEventTarget_Entry(this.field0): super._();
  

@override final  String field0;

/// Create a copy of MergeEventTarget
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MergeEventTarget_EntryCopyWith<MergeEventTarget_Entry> get copyWith => _$MergeEventTarget_EntryCopyWithImpl<MergeEventTarget_Entry>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MergeEventTarget_Entry&&(identical(other.field0, field0) || other.field0 == field0));
}


@override
int get hashCode => Object.hash(runtimeType,field0);

@override
String toString() {
  return 'MergeEventTarget.entry(field0: $field0)';
}


}

/// @nodoc
abstract mixin class $MergeEventTarget_EntryCopyWith<$Res> implements $MergeEventTargetCopyWith<$Res> {
  factory $MergeEventTarget_EntryCopyWith(MergeEventTarget_Entry value, $Res Function(MergeEventTarget_Entry) _then) = _$MergeEventTarget_EntryCopyWithImpl;
@override @useResult
$Res call({
 String field0
});




}
/// @nodoc
class _$MergeEventTarget_EntryCopyWithImpl<$Res>
    implements $MergeEventTarget_EntryCopyWith<$Res> {
  _$MergeEventTarget_EntryCopyWithImpl(this._self, this._then);

  final MergeEventTarget_Entry _self;
  final $Res Function(MergeEventTarget_Entry) _then;

/// Create a copy of MergeEventTarget
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? field0 = null,}) {
  return _then(MergeEventTarget_Entry(
null == field0 ? _self.field0 : field0 // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class MergeEventTarget_Group extends MergeEventTarget {
  const MergeEventTarget_Group(this.field0): super._();
  

@override final  String field0;

/// Create a copy of MergeEventTarget
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MergeEventTarget_GroupCopyWith<MergeEventTarget_Group> get copyWith => _$MergeEventTarget_GroupCopyWithImpl<MergeEventTarget_Group>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MergeEventTarget_Group&&(identical(other.field0, field0) || other.field0 == field0));
}


@override
int get hashCode => Object.hash(runtimeType,field0);

@override
String toString() {
  return 'MergeEventTarget.group(field0: $field0)';
}


}

/// @nodoc
abstract mixin class $MergeEventTarget_GroupCopyWith<$Res> implements $MergeEventTargetCopyWith<$Res> {
  factory $MergeEventTarget_GroupCopyWith(MergeEventTarget_Group value, $Res Function(MergeEventTarget_Group) _then) = _$MergeEventTarget_GroupCopyWithImpl;
@override @useResult
$Res call({
 String field0
});




}
/// @nodoc
class _$MergeEventTarget_GroupCopyWithImpl<$Res>
    implements $MergeEventTarget_GroupCopyWith<$Res> {
  _$MergeEventTarget_GroupCopyWithImpl(this._self, this._then);

  final MergeEventTarget_Group _self;
  final $Res Function(MergeEventTarget_Group) _then;

/// Create a copy of MergeEventTarget
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? field0 = null,}) {
  return _then(MergeEventTarget_Group(
null == field0 ? _self.field0 : field0 // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class MergeEventTarget_Icon extends MergeEventTarget {
  const MergeEventTarget_Icon(this.field0): super._();
  

@override final  String field0;

/// Create a copy of MergeEventTarget
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MergeEventTarget_IconCopyWith<MergeEventTarget_Icon> get copyWith => _$MergeEventTarget_IconCopyWithImpl<MergeEventTarget_Icon>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MergeEventTarget_Icon&&(identical(other.field0, field0) || other.field0 == field0));
}


@override
int get hashCode => Object.hash(runtimeType,field0);

@override
String toString() {
  return 'MergeEventTarget.icon(field0: $field0)';
}


}

/// @nodoc
abstract mixin class $MergeEventTarget_IconCopyWith<$Res> implements $MergeEventTargetCopyWith<$Res> {
  factory $MergeEventTarget_IconCopyWith(MergeEventTarget_Icon value, $Res Function(MergeEventTarget_Icon) _then) = _$MergeEventTarget_IconCopyWithImpl;
@override @useResult
$Res call({
 String field0
});




}
/// @nodoc
class _$MergeEventTarget_IconCopyWithImpl<$Res>
    implements $MergeEventTarget_IconCopyWith<$Res> {
  _$MergeEventTarget_IconCopyWithImpl(this._self, this._then);

  final MergeEventTarget_Icon _self;
  final $Res Function(MergeEventTarget_Icon) _then;

/// Create a copy of MergeEventTarget
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? field0 = null,}) {
  return _then(MergeEventTarget_Icon(
null == field0 ? _self.field0 : field0 // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
mixin _$VariantDictionaryValue {

 Object get field0;



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is VariantDictionaryValue&&const DeepCollectionEquality().equals(other.field0, field0));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(field0));

@override
String toString() {
  return 'VariantDictionaryValue(field0: $field0)';
}


}

/// @nodoc
class $VariantDictionaryValueCopyWith<$Res>  {
$VariantDictionaryValueCopyWith(VariantDictionaryValue _, $Res Function(VariantDictionaryValue) __);
}


/// Adds pattern-matching-related methods to [VariantDictionaryValue].
extension VariantDictionaryValuePatterns on VariantDictionaryValue {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( VariantDictionaryValue_UInt32 value)?  uInt32,TResult Function( VariantDictionaryValue_UInt64 value)?  uInt64,TResult Function( VariantDictionaryValue_Bool value)?  bool,TResult Function( VariantDictionaryValue_Int32 value)?  int32,TResult Function( VariantDictionaryValue_Int64 value)?  int64,TResult Function( VariantDictionaryValue_String value)?  string,TResult Function( VariantDictionaryValue_ByteArray value)?  byteArray,required TResult orElse(),}){
final _that = this;
switch (_that) {
case VariantDictionaryValue_UInt32() when uInt32 != null:
return uInt32(_that);case VariantDictionaryValue_UInt64() when uInt64 != null:
return uInt64(_that);case VariantDictionaryValue_Bool() when bool != null:
return bool(_that);case VariantDictionaryValue_Int32() when int32 != null:
return int32(_that);case VariantDictionaryValue_Int64() when int64 != null:
return int64(_that);case VariantDictionaryValue_String() when string != null:
return string(_that);case VariantDictionaryValue_ByteArray() when byteArray != null:
return byteArray(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( VariantDictionaryValue_UInt32 value)  uInt32,required TResult Function( VariantDictionaryValue_UInt64 value)  uInt64,required TResult Function( VariantDictionaryValue_Bool value)  bool,required TResult Function( VariantDictionaryValue_Int32 value)  int32,required TResult Function( VariantDictionaryValue_Int64 value)  int64,required TResult Function( VariantDictionaryValue_String value)  string,required TResult Function( VariantDictionaryValue_ByteArray value)  byteArray,}){
final _that = this;
switch (_that) {
case VariantDictionaryValue_UInt32():
return uInt32(_that);case VariantDictionaryValue_UInt64():
return uInt64(_that);case VariantDictionaryValue_Bool():
return bool(_that);case VariantDictionaryValue_Int32():
return int32(_that);case VariantDictionaryValue_Int64():
return int64(_that);case VariantDictionaryValue_String():
return string(_that);case VariantDictionaryValue_ByteArray():
return byteArray(_that);}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( VariantDictionaryValue_UInt32 value)?  uInt32,TResult? Function( VariantDictionaryValue_UInt64 value)?  uInt64,TResult? Function( VariantDictionaryValue_Bool value)?  bool,TResult? Function( VariantDictionaryValue_Int32 value)?  int32,TResult? Function( VariantDictionaryValue_Int64 value)?  int64,TResult? Function( VariantDictionaryValue_String value)?  string,TResult? Function( VariantDictionaryValue_ByteArray value)?  byteArray,}){
final _that = this;
switch (_that) {
case VariantDictionaryValue_UInt32() when uInt32 != null:
return uInt32(_that);case VariantDictionaryValue_UInt64() when uInt64 != null:
return uInt64(_that);case VariantDictionaryValue_Bool() when bool != null:
return bool(_that);case VariantDictionaryValue_Int32() when int32 != null:
return int32(_that);case VariantDictionaryValue_Int64() when int64 != null:
return int64(_that);case VariantDictionaryValue_String() when string != null:
return string(_that);case VariantDictionaryValue_ByteArray() when byteArray != null:
return byteArray(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( int field0)?  uInt32,TResult Function( BigInt field0)?  uInt64,TResult Function( bool field0)?  bool,TResult Function( int field0)?  int32,TResult Function( PlatformInt64 field0)?  int64,TResult Function( String field0)?  string,TResult Function( Uint8List field0)?  byteArray,required TResult orElse(),}) {final _that = this;
switch (_that) {
case VariantDictionaryValue_UInt32() when uInt32 != null:
return uInt32(_that.field0);case VariantDictionaryValue_UInt64() when uInt64 != null:
return uInt64(_that.field0);case VariantDictionaryValue_Bool() when bool != null:
return bool(_that.field0);case VariantDictionaryValue_Int32() when int32 != null:
return int32(_that.field0);case VariantDictionaryValue_Int64() when int64 != null:
return int64(_that.field0);case VariantDictionaryValue_String() when string != null:
return string(_that.field0);case VariantDictionaryValue_ByteArray() when byteArray != null:
return byteArray(_that.field0);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( int field0)  uInt32,required TResult Function( BigInt field0)  uInt64,required TResult Function( bool field0)  bool,required TResult Function( int field0)  int32,required TResult Function( PlatformInt64 field0)  int64,required TResult Function( String field0)  string,required TResult Function( Uint8List field0)  byteArray,}) {final _that = this;
switch (_that) {
case VariantDictionaryValue_UInt32():
return uInt32(_that.field0);case VariantDictionaryValue_UInt64():
return uInt64(_that.field0);case VariantDictionaryValue_Bool():
return bool(_that.field0);case VariantDictionaryValue_Int32():
return int32(_that.field0);case VariantDictionaryValue_Int64():
return int64(_that.field0);case VariantDictionaryValue_String():
return string(_that.field0);case VariantDictionaryValue_ByteArray():
return byteArray(_that.field0);}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( int field0)?  uInt32,TResult? Function( BigInt field0)?  uInt64,TResult? Function( bool field0)?  bool,TResult? Function( int field0)?  int32,TResult? Function( PlatformInt64 field0)?  int64,TResult? Function( String field0)?  string,TResult? Function( Uint8List field0)?  byteArray,}) {final _that = this;
switch (_that) {
case VariantDictionaryValue_UInt32() when uInt32 != null:
return uInt32(_that.field0);case VariantDictionaryValue_UInt64() when uInt64 != null:
return uInt64(_that.field0);case VariantDictionaryValue_Bool() when bool != null:
return bool(_that.field0);case VariantDictionaryValue_Int32() when int32 != null:
return int32(_that.field0);case VariantDictionaryValue_Int64() when int64 != null:
return int64(_that.field0);case VariantDictionaryValue_String() when string != null:
return string(_that.field0);case VariantDictionaryValue_ByteArray() when byteArray != null:
return byteArray(_that.field0);case _:
  return null;

}
}

}

/// @nodoc


class VariantDictionaryValue_UInt32 extends VariantDictionaryValue {
  const VariantDictionaryValue_UInt32(this.field0): super._();
  

@override final  int field0;

/// Create a copy of VariantDictionaryValue
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$VariantDictionaryValue_UInt32CopyWith<VariantDictionaryValue_UInt32> get copyWith => _$VariantDictionaryValue_UInt32CopyWithImpl<VariantDictionaryValue_UInt32>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is VariantDictionaryValue_UInt32&&(identical(other.field0, field0) || other.field0 == field0));
}


@override
int get hashCode => Object.hash(runtimeType,field0);

@override
String toString() {
  return 'VariantDictionaryValue.uInt32(field0: $field0)';
}


}

/// @nodoc
abstract mixin class $VariantDictionaryValue_UInt32CopyWith<$Res> implements $VariantDictionaryValueCopyWith<$Res> {
  factory $VariantDictionaryValue_UInt32CopyWith(VariantDictionaryValue_UInt32 value, $Res Function(VariantDictionaryValue_UInt32) _then) = _$VariantDictionaryValue_UInt32CopyWithImpl;
@useResult
$Res call({
 int field0
});




}
/// @nodoc
class _$VariantDictionaryValue_UInt32CopyWithImpl<$Res>
    implements $VariantDictionaryValue_UInt32CopyWith<$Res> {
  _$VariantDictionaryValue_UInt32CopyWithImpl(this._self, this._then);

  final VariantDictionaryValue_UInt32 _self;
  final $Res Function(VariantDictionaryValue_UInt32) _then;

/// Create a copy of VariantDictionaryValue
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? field0 = null,}) {
  return _then(VariantDictionaryValue_UInt32(
null == field0 ? _self.field0 : field0 // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc


class VariantDictionaryValue_UInt64 extends VariantDictionaryValue {
  const VariantDictionaryValue_UInt64(this.field0): super._();
  

@override final  BigInt field0;

/// Create a copy of VariantDictionaryValue
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$VariantDictionaryValue_UInt64CopyWith<VariantDictionaryValue_UInt64> get copyWith => _$VariantDictionaryValue_UInt64CopyWithImpl<VariantDictionaryValue_UInt64>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is VariantDictionaryValue_UInt64&&(identical(other.field0, field0) || other.field0 == field0));
}


@override
int get hashCode => Object.hash(runtimeType,field0);

@override
String toString() {
  return 'VariantDictionaryValue.uInt64(field0: $field0)';
}


}

/// @nodoc
abstract mixin class $VariantDictionaryValue_UInt64CopyWith<$Res> implements $VariantDictionaryValueCopyWith<$Res> {
  factory $VariantDictionaryValue_UInt64CopyWith(VariantDictionaryValue_UInt64 value, $Res Function(VariantDictionaryValue_UInt64) _then) = _$VariantDictionaryValue_UInt64CopyWithImpl;
@useResult
$Res call({
 BigInt field0
});




}
/// @nodoc
class _$VariantDictionaryValue_UInt64CopyWithImpl<$Res>
    implements $VariantDictionaryValue_UInt64CopyWith<$Res> {
  _$VariantDictionaryValue_UInt64CopyWithImpl(this._self, this._then);

  final VariantDictionaryValue_UInt64 _self;
  final $Res Function(VariantDictionaryValue_UInt64) _then;

/// Create a copy of VariantDictionaryValue
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? field0 = null,}) {
  return _then(VariantDictionaryValue_UInt64(
null == field0 ? _self.field0 : field0 // ignore: cast_nullable_to_non_nullable
as BigInt,
  ));
}


}

/// @nodoc


class VariantDictionaryValue_Bool extends VariantDictionaryValue {
  const VariantDictionaryValue_Bool(this.field0): super._();
  

@override final  bool field0;

/// Create a copy of VariantDictionaryValue
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$VariantDictionaryValue_BoolCopyWith<VariantDictionaryValue_Bool> get copyWith => _$VariantDictionaryValue_BoolCopyWithImpl<VariantDictionaryValue_Bool>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is VariantDictionaryValue_Bool&&(identical(other.field0, field0) || other.field0 == field0));
}


@override
int get hashCode => Object.hash(runtimeType,field0);

@override
String toString() {
  return 'VariantDictionaryValue.bool(field0: $field0)';
}


}

/// @nodoc
abstract mixin class $VariantDictionaryValue_BoolCopyWith<$Res> implements $VariantDictionaryValueCopyWith<$Res> {
  factory $VariantDictionaryValue_BoolCopyWith(VariantDictionaryValue_Bool value, $Res Function(VariantDictionaryValue_Bool) _then) = _$VariantDictionaryValue_BoolCopyWithImpl;
@useResult
$Res call({
 bool field0
});




}
/// @nodoc
class _$VariantDictionaryValue_BoolCopyWithImpl<$Res>
    implements $VariantDictionaryValue_BoolCopyWith<$Res> {
  _$VariantDictionaryValue_BoolCopyWithImpl(this._self, this._then);

  final VariantDictionaryValue_Bool _self;
  final $Res Function(VariantDictionaryValue_Bool) _then;

/// Create a copy of VariantDictionaryValue
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? field0 = null,}) {
  return _then(VariantDictionaryValue_Bool(
null == field0 ? _self.field0 : field0 // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

/// @nodoc


class VariantDictionaryValue_Int32 extends VariantDictionaryValue {
  const VariantDictionaryValue_Int32(this.field0): super._();
  

@override final  int field0;

/// Create a copy of VariantDictionaryValue
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$VariantDictionaryValue_Int32CopyWith<VariantDictionaryValue_Int32> get copyWith => _$VariantDictionaryValue_Int32CopyWithImpl<VariantDictionaryValue_Int32>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is VariantDictionaryValue_Int32&&(identical(other.field0, field0) || other.field0 == field0));
}


@override
int get hashCode => Object.hash(runtimeType,field0);

@override
String toString() {
  return 'VariantDictionaryValue.int32(field0: $field0)';
}


}

/// @nodoc
abstract mixin class $VariantDictionaryValue_Int32CopyWith<$Res> implements $VariantDictionaryValueCopyWith<$Res> {
  factory $VariantDictionaryValue_Int32CopyWith(VariantDictionaryValue_Int32 value, $Res Function(VariantDictionaryValue_Int32) _then) = _$VariantDictionaryValue_Int32CopyWithImpl;
@useResult
$Res call({
 int field0
});




}
/// @nodoc
class _$VariantDictionaryValue_Int32CopyWithImpl<$Res>
    implements $VariantDictionaryValue_Int32CopyWith<$Res> {
  _$VariantDictionaryValue_Int32CopyWithImpl(this._self, this._then);

  final VariantDictionaryValue_Int32 _self;
  final $Res Function(VariantDictionaryValue_Int32) _then;

/// Create a copy of VariantDictionaryValue
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? field0 = null,}) {
  return _then(VariantDictionaryValue_Int32(
null == field0 ? _self.field0 : field0 // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc


class VariantDictionaryValue_Int64 extends VariantDictionaryValue {
  const VariantDictionaryValue_Int64(this.field0): super._();
  

@override final  PlatformInt64 field0;

/// Create a copy of VariantDictionaryValue
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$VariantDictionaryValue_Int64CopyWith<VariantDictionaryValue_Int64> get copyWith => _$VariantDictionaryValue_Int64CopyWithImpl<VariantDictionaryValue_Int64>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is VariantDictionaryValue_Int64&&(identical(other.field0, field0) || other.field0 == field0));
}


@override
int get hashCode => Object.hash(runtimeType,field0);

@override
String toString() {
  return 'VariantDictionaryValue.int64(field0: $field0)';
}


}

/// @nodoc
abstract mixin class $VariantDictionaryValue_Int64CopyWith<$Res> implements $VariantDictionaryValueCopyWith<$Res> {
  factory $VariantDictionaryValue_Int64CopyWith(VariantDictionaryValue_Int64 value, $Res Function(VariantDictionaryValue_Int64) _then) = _$VariantDictionaryValue_Int64CopyWithImpl;
@useResult
$Res call({
 PlatformInt64 field0
});




}
/// @nodoc
class _$VariantDictionaryValue_Int64CopyWithImpl<$Res>
    implements $VariantDictionaryValue_Int64CopyWith<$Res> {
  _$VariantDictionaryValue_Int64CopyWithImpl(this._self, this._then);

  final VariantDictionaryValue_Int64 _self;
  final $Res Function(VariantDictionaryValue_Int64) _then;

/// Create a copy of VariantDictionaryValue
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? field0 = null,}) {
  return _then(VariantDictionaryValue_Int64(
null == field0 ? _self.field0 : field0 // ignore: cast_nullable_to_non_nullable
as PlatformInt64,
  ));
}


}

/// @nodoc


class VariantDictionaryValue_String extends VariantDictionaryValue {
  const VariantDictionaryValue_String(this.field0): super._();
  

@override final  String field0;

/// Create a copy of VariantDictionaryValue
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$VariantDictionaryValue_StringCopyWith<VariantDictionaryValue_String> get copyWith => _$VariantDictionaryValue_StringCopyWithImpl<VariantDictionaryValue_String>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is VariantDictionaryValue_String&&(identical(other.field0, field0) || other.field0 == field0));
}


@override
int get hashCode => Object.hash(runtimeType,field0);

@override
String toString() {
  return 'VariantDictionaryValue.string(field0: $field0)';
}


}

/// @nodoc
abstract mixin class $VariantDictionaryValue_StringCopyWith<$Res> implements $VariantDictionaryValueCopyWith<$Res> {
  factory $VariantDictionaryValue_StringCopyWith(VariantDictionaryValue_String value, $Res Function(VariantDictionaryValue_String) _then) = _$VariantDictionaryValue_StringCopyWithImpl;
@useResult
$Res call({
 String field0
});




}
/// @nodoc
class _$VariantDictionaryValue_StringCopyWithImpl<$Res>
    implements $VariantDictionaryValue_StringCopyWith<$Res> {
  _$VariantDictionaryValue_StringCopyWithImpl(this._self, this._then);

  final VariantDictionaryValue_String _self;
  final $Res Function(VariantDictionaryValue_String) _then;

/// Create a copy of VariantDictionaryValue
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? field0 = null,}) {
  return _then(VariantDictionaryValue_String(
null == field0 ? _self.field0 : field0 // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class VariantDictionaryValue_ByteArray extends VariantDictionaryValue {
  const VariantDictionaryValue_ByteArray(this.field0): super._();
  

@override final  Uint8List field0;

/// Create a copy of VariantDictionaryValue
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$VariantDictionaryValue_ByteArrayCopyWith<VariantDictionaryValue_ByteArray> get copyWith => _$VariantDictionaryValue_ByteArrayCopyWithImpl<VariantDictionaryValue_ByteArray>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is VariantDictionaryValue_ByteArray&&const DeepCollectionEquality().equals(other.field0, field0));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(field0));

@override
String toString() {
  return 'VariantDictionaryValue.byteArray(field0: $field0)';
}


}

/// @nodoc
abstract mixin class $VariantDictionaryValue_ByteArrayCopyWith<$Res> implements $VariantDictionaryValueCopyWith<$Res> {
  factory $VariantDictionaryValue_ByteArrayCopyWith(VariantDictionaryValue_ByteArray value, $Res Function(VariantDictionaryValue_ByteArray) _then) = _$VariantDictionaryValue_ByteArrayCopyWithImpl;
@useResult
$Res call({
 Uint8List field0
});




}
/// @nodoc
class _$VariantDictionaryValue_ByteArrayCopyWithImpl<$Res>
    implements $VariantDictionaryValue_ByteArrayCopyWith<$Res> {
  _$VariantDictionaryValue_ByteArrayCopyWithImpl(this._self, this._then);

  final VariantDictionaryValue_ByteArray _self;
  final $Res Function(VariantDictionaryValue_ByteArray) _then;

/// Create a copy of VariantDictionaryValue
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? field0 = null,}) {
  return _then(VariantDictionaryValue_ByteArray(
null == field0 ? _self.field0 : field0 // ignore: cast_nullable_to_non_nullable
as Uint8List,
  ));
}


}

// dart format on
